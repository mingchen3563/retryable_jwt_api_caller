import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

class HttpService {
  final http.Client httpClient;
  HttpService({http.Client? httpClient})
      : httpClient = httpClient ?? GetIt.I.get<http.Client>();

  Future<http.Response> get({
    required String host,
    required String path,
    required Map<String, String> headers,
  }) async {
    Uri uri = Uri.https(host, path);
    return httpClient.get(
      uri,
      headers: headers,
    );
  }

  Future<http.Response> post({
    required String host,
    required String path,
    required Map<String, String> headers,
    required String body,
  }) async {
    Uri uri = Uri.https(host, path);
    return httpClient.post(
      uri,
      headers: headers,
      body: body,
    );
  }

  Future<http.Response> put({
    required String host,
    required String path,
    required Map<String, String> headers,
    required String body,
  }) async {
    Uri uri = Uri.https(host, path);
    return httpClient.put(
      uri,
      headers: headers,
      body: body,
    );
  }

  Future<http.Response> patch({
    required String host,
    required String path,
    required Map<String, String> headers,
    required String body,
  }) async {
    Uri uri = Uri.https(host, path);
    return httpClient.patch(
      uri,
      headers: headers,
      body: body,
    );
  }

  Future<http.Response> delete({
    required String host,
    required String path,
    required Map<String, String> headers,
  }) async {
    Uri uri = Uri.https(host, path);
    return httpClient.delete(
      uri,
      headers: headers,
    );
  }
}
