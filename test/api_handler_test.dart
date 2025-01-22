import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:retryable_jwt_api_caller/api_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_handler_test.mocks.dart';

@GenerateMocks([
  SharedPreferences,
  Dio,
])
void main() {
  late MockSharedPreferences mockSharedPreferences;
  late MockDio mockDio;
  late ApiHandler apiHandler;

  setUpAll(() async {
    mockSharedPreferences = MockSharedPreferences();
    mockDio = MockDio();
    apiHandler = await ApiHandler.create(
      baseUrl: 'https://api.example.com',
      authType: AuthType.dynamicToken,
      refreshTokenPath: '/refresh',
      tokenFromJson: (json, oldToken) {
        return DynamicTokens(
          accessToken: json['accessToken'],
          idToken: json['idToken'],
          refreshToken: json['refreshToken'],
          sub: json['sub'],
        );
      },
      refreshTokenPayloadBuilder: (rToken, sub) {
        return {
          'refreshToken': rToken,
          'sub': sub,
        };
      },
      injectDio: mockDio,
      injectPrefs: mockSharedPreferences,
    );
  });

  group('api handler', () {
    test('test get token ...', () async {
      // stub
      when(mockSharedPreferences.getString('accessToken')).thenReturn('accessToken');
      when(mockSharedPreferences.getString('idToken')).thenReturn('idToken');
      when(mockSharedPreferences.getString('refreshToken')).thenReturn('refreshToken');
      when(mockSharedPreferences.getString('sub')).thenReturn('sub');

      // act
      // final tokens = await apiHandler._getStoredTokens();

      // assert
      // expect(tokens, isNotNull);
      // expect(tokens?.accessToken, 'accessToken');
      // expect(tokens?.idToken, 'idToken');
      // expect(tokens?.refreshToken, 'refreshToken');
      // expect(tokens?.sub, 'sub');
      
    });
  });
}
