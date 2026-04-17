import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/core/api_client.dart';
import 'package:sofia_bike_nav/data/api/backend_api.dart';
import 'package:sofia_bike_nav/data/models/bike_profile.dart';
import 'package:sofia_bike_nav/data/models/lat_lng_point.dart';
import 'package:sofia_bike_nav/data/models/route_request.dart';

typedef _FakeResponder = Future<ResponseBody> Function(RequestOptions o);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._respond);

  final _FakeResponder _respond;
  final List<RequestOptions> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    calls.add(options);
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(dynamic body, {int status = 200}) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

ResponseBody _text(String body, {int status = 200}) {
  return ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: ['text/plain'],
    },
  );
}

BackendApi _apiWith(HttpClientAdapter adapter) {
  final client = ApiClient();
  client.dio.httpClientAdapter = adapter;
  return BackendApi(client);
}

void main() {
  group('BackendApi.getRoute', () {
    test('POSTs to /api/v1/route with serialised request', () async {
      final adapter = _FakeAdapter((o) async => _json({
            'distance_km': 1.5,
            'duration_minutes': 5.0,
            'polyline': 'abc',
          }));
      final api = _apiWith(adapter);

      final res = await api.getRoute(const RouteRequestDto(
        start: LatLngPoint(1, 2),
        end: LatLngPoint(3, 4),
        profile: BikeProfileId.cityBike,
      ));

      expect(res.distanceKm, 1.5);
      expect(res.durationMinutes, 5.0);
      expect(res.polyline, 'abc');
      expect(adapter.calls, hasLength(1));
      final call = adapter.calls.single;
      expect(call.method, 'POST');
      expect(call.path, '/api/v1/route');
      expect(call.data, isA<Map<String, dynamic>>());
      expect((call.data as Map)['profile'], 'city_bike');
    });

    test('wraps DioException into ApiException with server detail', () async {
      final adapter = _FakeAdapter(
        (o) async => _json({'detail': 'bad request'}, status: 400),
      );
      final api = _apiWith(adapter);

      await expectLater(
        api.getRoute(const RouteRequestDto(
          start: LatLngPoint(1, 2),
          end: LatLngPoint(3, 4),
          profile: BikeProfileId.cityBike,
        )),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', 'bad request')),
      );
    });

    test('falls back to DioException message when no detail key', () async {
      final adapter = _FakeAdapter(
        (o) async => _json({}, status: 500),
      );
      final api = _apiWith(adapter);

      try {
        await api.getRoute(const RouteRequestDto(
          start: LatLngPoint(0, 0),
          end: LatLngPoint(1, 1),
          profile: BikeProfileId.cityBike,
        ));
        fail('expected ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 500);
        expect(e.message, isNotEmpty);
      }
    });
  });

  group('BackendApi.listProfiles', () {
    test('GETs /api/v1/profiles and parses list', () async {
      final adapter = _FakeAdapter((o) async => _json([
            {
              'name': 'city_bike',
              'display_name': 'City',
              'description': 'Urban',
              'bicycle_type': 'hybrid',
              'use_roads': 0.5,
              'use_hills': 0.5,
              'cycling_speed': 15.0,
            },
          ]));
      final api = _apiWith(adapter);

      final profiles = await api.listProfiles();
      expect(profiles, hasLength(1));
      expect(profiles.first.name, 'city_bike');
      expect(adapter.calls.single.method, 'GET');
      expect(adapter.calls.single.path, '/api/v1/profiles');
    });

    test('maps DioException to ApiException', () async {
      final adapter = _FakeAdapter(
        (o) async => _json({'detail': 'boom'}, status: 502),
      );
      final api = _apiWith(adapter);
      await expectLater(
        api.listProfiles(),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'code', 502)
            .having((e) => e.message, 'message', 'boom')),
      );
    });
  });

  group('BackendApi.getBikeLanesGeoJson', () {
    test('returns plain response body', () async {
      const geojson = '{"type":"FeatureCollection","features":[]}';
      final adapter = _FakeAdapter((o) async => _text(geojson));
      final api = _apiWith(adapter);
      final body = await api.getBikeLanesGeoJson();
      expect(body, geojson);
      expect(adapter.calls.single.path, '/api/v1/bike-lanes');
    });

    test('maps DioException to ApiException', () async {
      final adapter = _FakeAdapter(
        (o) async => _text('err', status: 503),
      );
      final api = _apiWith(adapter);
      await expectLater(
        api.getBikeLanesGeoJson(),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'code', 503)),
      );
    });
  });

  group('BackendApi.geocode', () {
    test('GETs with query params and parses results', () async {
      final adapter = _FakeAdapter((o) async => _json([
            {'label': 'Sofia', 'lat': 42.0, 'lon': 23.0},
          ]));
      final api = _apiWith(adapter);

      final results = await api.geocode('sofia', limit: 5);
      expect(results, hasLength(1));
      expect(results.first.label, 'Sofia');
      final call = adapter.calls.single;
      expect(call.path, '/api/v1/geocode');
      expect(call.queryParameters['q'], 'sofia');
      expect(call.queryParameters['limit'], 5);
    });

    test('default limit is 10', () async {
      final adapter = _FakeAdapter((o) async => _json(const []));
      final api = _apiWith(adapter);
      await api.geocode('x');
      expect(adapter.calls.single.queryParameters['limit'], 10);
    });

    test('maps DioException to ApiException', () async {
      final adapter = _FakeAdapter(
        (o) async => _json({'detail': 'bad query'}, status: 400),
      );
      final api = _apiWith(adapter);
      await expectLater(
        api.geocode('bad'),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'bad query')),
      );
    });
  });
}
