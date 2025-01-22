import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:retryable_jwt_api_caller/src/domain/enums/auth_type.dart';
import 'package:retryable_jwt_api_caller/src/domain/value_objects/dynamic_tokens.dart';
import 'package:retryable_jwt_api_caller/src/domain/enums/token_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:retryable_jwt_api_caller/src/domain/enums/auth_type.dart';
export 'package:retryable_jwt_api_caller/src/domain/enums/token_type.dart';
export 'package:retryable_jwt_api_caller/src/domain/value_objects/dynamic_tokens.dart';

class ApiHandler {
  final Dio _dio;
  final SharedPreferences _prefs;
  final String baseUrl;
  final AuthType authType;
  final String? staticToken;
  final String? refreshTokenPath;
  final Map<String, dynamic>? addHeaders;
  final DynamicTokens Function(Map<String, dynamic>, DynamicTokens?)?
      tokenFromJson;
  final Map<String, dynamic> Function(String refreshToken, String sub)?
      refreshTokenPayloadBuilder;
  final TokenType? tokenType;

  static const String _tokenKey = 'dynamic_tokens';

  ApiHandler._({
    required this.baseUrl,
    required this.authType,
    required this.staticToken,
    this.refreshTokenPath,
    this.tokenFromJson,
    required SharedPreferences prefs,
    required Dio dio,
    this.refreshTokenPayloadBuilder,
    this.tokenType,
    this.addHeaders,
  })  : assert(
          authType == AuthType.staticToken ||
              (refreshTokenPath != null &&
                  tokenFromJson != null &&
                  refreshTokenPayloadBuilder != null &&
                  tokenType != null),
          'refreshTokenPath, tokenFromJson, refreshTokenPayloadBuilder and tokenType must not be null for dynamic token',
        ),
        assert(
          authType == AuthType.dynamicToken ||
              (staticToken != null && tokenType == null),
          'staticToken must not be null and tokenType must be null for static token',
        ),
        _dio = dio,
        _prefs = prefs {
    _dio.options.baseUrl = baseUrl;
    _setupInterceptors();
  }

  static Future<ApiHandler> create({
    required String baseUrl,
    required AuthType authType,
    String? staticToken,
    String? refreshTokenPath,
    DynamicTokens Function(Map<String, dynamic>, DynamicTokens?)? tokenFromJson,
    Map<String, dynamic> Function(String refreshToken, String sub)?
        refreshTokenPayloadBuilder,
    TokenType? tokenType,
    Dio? injectDio,
    SharedPreferences? injectPrefs,
    Map<String, dynamic>? addHeaders,
  }) async {
    if (authType == AuthType.dynamicToken) {
      if (refreshTokenPath == null) {
        throw ArgumentError('refreshTokenPath is required for dynamic token');
      }
      if (tokenFromJson == null) {
        throw ArgumentError('tokenFromJson is required for dynamic token');
      }
      if (tokenType == null) {
        throw ArgumentError('tokenType is required for dynamic token');
      }
    } else if (authType == AuthType.staticToken) {
      if (staticToken == null) {
        throw ArgumentError('staticToken is required for static token');
      }
      if (tokenType != null) {
        throw ArgumentError('tokenType must be null for static token');
      }
    }

    final prefs = injectPrefs ?? await SharedPreferences.getInstance();
    final dio = injectDio ?? Dio();
    return ApiHandler._(
      baseUrl: baseUrl,
      authType: authType,
      staticToken: staticToken,
      refreshTokenPath: refreshTokenPath,
      tokenFromJson: tokenFromJson,
      prefs: prefs,
      dio: dio,
      addHeaders: addHeaders,
      refreshTokenPayloadBuilder: authType == AuthType.dynamicToken
          ? (refreshTokenPayloadBuilder ??
              ((refreshToken, sub) => {
                    'refreshToken': refreshToken,
                    'sub': sub,
                  }))
          : null,
      tokenType: tokenType,
    );
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (authType == AuthType.staticToken) {
            options.headers['Authorization'] = 'Bearer $staticToken';
          } else {
            final tokens = await _getStoredTokens();
            if (tokens != null) {
              final token = tokenType == TokenType.idToken
                  ? tokens.idToken
                  : tokens.accessToken;
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          if (addHeaders != null) {
            options.headers.addAll(addHeaders!);
          }
          log('${options.method} ${options.path}');

          return handler.next(options);
        },
        onError: (error, handler) async {
          log('dio on error: ${error.response?.statusCode}');
          if (error.response?.statusCode == 401 &&
              authType == AuthType.dynamicToken) {
            final tokens = await _getStoredTokens();
            if (tokens != null) {
              try {
                final newTokens = await _refreshTokens(tokens);
                await _storeTokens(newTokens);
                final token = tokenType == TokenType.idToken
                    ? newTokens.idToken
                    : newTokens.accessToken;
                error.requestOptions.headers['Authorization'] = 'Bearer $token';
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e,s) {
                log('refresh token error: $e' ,stackTrace: s);
                return handler.reject(error);
              }
            }
          }
          if (error.response?.statusCode == 500) {
            // log full request path and method
            log('${error.requestOptions.method} ${error.requestOptions.baseUrl}${error.requestOptions.path}');
            // log body
            log('request body:\n${error.requestOptions.data}');
            // log response
            log('response body:\n${error.response?.data}');
          }
          return handler.reject(error);
        },
      ),
    );
  }

  Future<void> setDynamicTokens(DynamicTokens tokens) async {
    await _storeTokens(tokens);
  }

  Future<void> _storeTokens(DynamicTokens tokens) async {
    await _prefs.setString(_tokenKey, jsonEncode(tokens.toJson()));
  }

  Future<DynamicTokens?> _getStoredTokens() async {
    if (authType != AuthType.dynamicToken || tokenFromJson == null) return null;
    final tokenStr = _prefs.getString(_tokenKey);
    if (tokenStr == null) {
      return null;
    }

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(tokenStr);

      DynamicTokens tokens = DynamicTokens.fromJson(jsonMap);
      return tokens;
    } catch (e) {
      log('getStoredTokens error: $e');
      return null;
    }
  }

  Future<DynamicTokens> _refreshTokens(DynamicTokens oldTokens) async {
    if (authType != AuthType.dynamicToken ||
        refreshTokenPath == null ||
        tokenFromJson == null ||
        refreshTokenPayloadBuilder == null) {
      throw StateError('Refresh token is not supported for static token');
    }

    final payload = refreshTokenPayloadBuilder!(
      oldTokens.refreshToken,
      oldTokens.sub,
    );

    final response = await (Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $staticToken',
        },
      ),
    )..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                log('refresh token request');
                log('${options.method} ${options.baseUrl}${options.path}');
                log('request headers:\n${options.headers}');
                log('request body:\n${options.data}');

                return handler.next(options);
              },
              onResponse: (response, handler) {
                log('refresh token response');
                log('${response.statusCode} ${response.requestOptions.baseUrl}${response.requestOptions.path}');
                log('response body:\n${response.data}');

                return handler.next(response);
              },
              onError: (error, handler) {
                log('refresh token error');
                log('${error.response?.statusCode} ${error.requestOptions.baseUrl}${error.requestOptions.path}');
                log('error body:\n${error.response?.data}');

                return handler.next(error);
              },
            ),
          ))
        .post(
      refreshTokenPath!,
      data: payload,
    );

    if (response.statusCode == 200) {
      return tokenFromJson!(response.data, oldTokens);
    } else {
      throw Exception('Failed to refresh tokens');
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(
      path,
      queryParameters: queryParameters,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<void> clearTokens() async {
    await _clearTokens();
  }

  Future<void> dispose() async {
    await _clearTokens();
  }

  Future<void> _clearTokens() async {
    await _prefs.remove(_tokenKey);
  }
}
