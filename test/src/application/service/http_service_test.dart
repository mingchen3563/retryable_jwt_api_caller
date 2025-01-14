import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:retryable_jwt_api_caller/src/application/service/http_service.dart';

import 'http_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late HttpService httpService;
  late http.Client mockHttpClient;
  setUpAll(() {
    mockHttpClient = MockClient();
    httpService = HttpService(httpClient: mockHttpClient);
  });
  group('test injection', () {
    test('test direct injection', () {
      // arrange
      final httpService = HttpService(httpClient: mockHttpClient);
      // assert
      expect(httpService.httpClient, mockHttpClient);
    });
    test('test get it injection', () {
      // arrange
      GetIt.I.registerSingleton<http.Client>(mockHttpClient);
      final httpService = HttpService();
      // assert
      expect(httpService.httpClient, mockHttpClient);
    });
  });

  group('test http services', () {
    test('test get..', () async {
      // arrange
      const host = 'api.example.com';
      const path = '/path';
      const headers = {'Content-Type': 'application/json'};

      // stub
      when(mockHttpClient.get(
        Uri.https(host, path),
        headers: headers,
      )).thenAnswer((_) async => http.Response('{"id": 1}', 200));
      // act
      final response = await httpService.get(
        host: host,
        path: path,
        headers: headers,
      );
      // assert
      verify(mockHttpClient.get(
        Uri.https(host, path),
        headers: headers,
      )).called(1);
      expect(response.statusCode, 200);
    });
    test('test post...', () async {
      // arrange
      const host = 'api.example.com';
      const path = '/path';
      const headers = {'Content-Type': 'application/json'};
      const body = '{"id": 1}';
      // stub
      when(mockHttpClient.post(
        Uri.https(host, path),
        headers: headers,
        body: body,
      )).thenAnswer((_) async => http.Response('{"id": 1}', 200));
      // act
      final response = await httpService.post(
        host: host,
        path: path,
        headers: headers,
        body: body,
      );
      // assert

      verify(mockHttpClient.post(
        Uri.https(host, path),
        headers: headers,
        body: body,
      )).called(1);
      expect(response.statusCode, 200);
    });

    test('test put...', () async {
      // arrange
      const host = 'api.example.com';
      const path = '/path';
      const headers = {'Content-Type': 'application/json'};
      const body = '{"id": 1}';
      // stub
      when(mockHttpClient.put(
        Uri.https(host, path),
        headers: headers,
        body: body,
      )).thenAnswer((_) async => http.Response('{"id": 1}', 200));
      // act
      final response = await httpService.put(
        host: host,
        path: path,
        headers: headers,
        body: body,
      );
      // assert

      verify(mockHttpClient.put(
        Uri.https(host, path),
        headers: headers,
        body: body,
      )).called(1);
      expect(response.statusCode, 200);
    });
    test('test patch...', () async {
      // arrange
      const host = 'api.example.com';
      const path = '/path';
      const headers = {'Content-Type': 'application/json'};
      const body = '{"id": 1}';
      // stub
      when(mockHttpClient.patch(
        Uri.https(host, path),
        headers: headers,
        body: body,
      )).thenAnswer((_) async => http.Response('{"id": 1}', 200));
      // act
      final response = await httpService.patch(
        host: host,
        path: path,
        headers: headers,
        body: body,
      );
      // assert

      verify(mockHttpClient.patch(
        Uri.https(host, path),
        headers: headers,
        body: body,
      )).called(1);
      expect(response.statusCode, 200);
    });
    test('test delete...', () async {
      // arrange
      const host = 'api.example.com';
      const path = '/path';
      const headers = {'Content-Type': 'application/json'};
      // stub
      when(mockHttpClient.delete(
        Uri.https(host, path),
        headers: headers,
      )).thenAnswer((_) async => http.Response('{"id": 1}', 200));
      // act
      final response = await httpService.delete(
        host: host,
        path: path,
        headers: headers,
      );
      // assert
      // assert

      verify(mockHttpClient.delete(
        Uri.https(host, path),
        headers: headers,
      )).called(1);
      expect(response.statusCode, 200);
    });
  });
}
