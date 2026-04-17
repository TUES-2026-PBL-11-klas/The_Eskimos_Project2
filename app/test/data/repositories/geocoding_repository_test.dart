import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/core/api_client.dart';
import 'package:sofia_bike_nav/data/api/backend_api.dart';
import 'package:sofia_bike_nav/data/repositories/geocoding_repository.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);
  final List<dynamic> body;
  final List<RequestOptions> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

BackendApi _api(_FakeAdapter adapter) {
  final c = ApiClient();
  c.dio.httpClientAdapter = adapter;
  return BackendApi(c);
}

void main() {
  group('GeocodingRepository', () {
    test('returns empty list without calling API for short queries', () async {
      final adapter = _FakeAdapter([]);
      final repo = GeocodingRepository(_api(adapter));
      expect(await repo.search(''), isEmpty);
      expect(await repo.search(' '), isEmpty);
      expect(await repo.search('a'), isEmpty);
      expect(adapter.calls, isEmpty);
    });

    test('calls API with trimmed query', () async {
      final adapter = _FakeAdapter([
        {'label': 'Sofia', 'lat': 42.0, 'lon': 23.0},
      ]);
      final repo = GeocodingRepository(_api(adapter));
      final res = await repo.search('  sof  ');
      expect(res, hasLength(1));
      expect(res.first.label, 'Sofia');
      expect(adapter.calls.single.queryParameters['q'], 'sof');
      expect(adapter.calls.single.queryParameters['limit'], 10);
    });

    test('forwards custom limit', () async {
      final adapter = _FakeAdapter(const []);
      final repo = GeocodingRepository(_api(adapter));
      await repo.search('abcd', limit: 3);
      expect(adapter.calls.single.queryParameters['limit'], 3);
    });
  });
}
