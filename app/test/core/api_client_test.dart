import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/core/api_client.dart';
import 'package:sofia_bike_nav/core/config.dart';

void main() {
  group('ApiClient', () {
    test('configures Dio with backend base URL and JSON header', () {
      final c = ApiClient();
      expect(c.dio.options.baseUrl, AppConfig.backendBaseUrl);
      expect(c.dio.options.headers['Content-Type'], 'application/json');
      expect(c.dio.options.connectTimeout, const Duration(seconds: 10));
      expect(c.dio.options.receiveTimeout, const Duration(seconds: 30));
    });
  });

  group('ApiException', () {
    test('toString includes status code and message', () {
      final e = ApiException(404, 'not found');
      expect(e.statusCode, 404);
      expect(e.message, 'not found');
      expect(e.toString(), 'ApiException(404): not found');
    });

    test('accepts null status code', () {
      final e = ApiException(null, 'network down');
      expect(e.statusCode, isNull);
      expect(e.toString(), contains('network down'));
    });
  });
}
