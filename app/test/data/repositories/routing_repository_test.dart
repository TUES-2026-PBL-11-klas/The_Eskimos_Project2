import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/core/api_client.dart';
import 'package:sofia_bike_nav/data/api/backend_api.dart';
import 'package:sofia_bike_nav/data/db/routes_dao.dart';
import 'package:sofia_bike_nav/data/models/bike_profile.dart';
import 'package:sofia_bike_nav/data/models/lat_lng_point.dart';
import 'package:sofia_bike_nav/data/models/route_response.dart';
import 'package:sofia_bike_nav/data/repositories/routing_repository.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.response);

  final Map<String, dynamic> response;
  int postCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    postCalls++;
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(response)),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeRoutesDao implements RoutesDao {
  _FakeRoutesDao({this.cached});
  RouteResponseDto? cached;
  final List<String> getCalls = [];
  final List<String> putCalls = [];
  BikeProfileId? lastProfile;

  @override
  Future<RouteResponseDto?> get(String id) async {
    getCalls.add(id);
    return cached;
  }

  @override
  Future<void> put(String id, RouteResponseDto route, BikeProfileId p) async {
    putCalls.add(id);
    lastProfile = p;
    cached = route;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

BackendApi _api(Map<String, dynamic> response) {
  final c = ApiClient();
  c.dio.httpClientAdapter = _FakeAdapter(response);
  return BackendApi(c);
}

void main() {
  group('RoutingRepository', () {
    test('returns cached route without calling API when cache hit', () async {
      const cached = RouteResponseDto(
        distanceKm: 1.0,
        durationMinutes: 5.0,
        polyline: 'cached',
        maneuvers: [],
      );
      final dao = _FakeRoutesDao(cached: cached);
      final adapter = _FakeAdapter(const {});
      final client = ApiClient()..dio.httpClientAdapter = adapter;
      final repo = RoutingRepository(BackendApi(client), dao);

      final result = await repo.fetch(
        start: const LatLngPoint(1, 2),
        end: const LatLngPoint(3, 4),
        profile: BikeProfileId.cityBike,
      );

      expect(result.polyline, 'cached');
      expect(dao.getCalls, hasLength(1));
      expect(dao.putCalls, isEmpty);
      expect(adapter.postCalls, 0);
    });

    test('fetches from API and caches when no cache hit', () async {
      final dao = _FakeRoutesDao();
      final api = _api({
        'distance_km': 2.0,
        'duration_minutes': 8.0,
        'polyline': 'fresh',
      });
      final repo = RoutingRepository(api, dao);

      final result = await repo.fetch(
        start: const LatLngPoint(1, 2),
        end: const LatLngPoint(3, 4),
        profile: BikeProfileId.mountainBike,
      );

      expect(result.polyline, 'fresh');
      expect(dao.putCalls, hasLength(1));
      expect(dao.lastProfile, BikeProfileId.mountainBike);
      final id = RoutesDao.idFor(
        const LatLngPoint(1, 2),
        const LatLngPoint(3, 4),
        BikeProfileId.mountainBike,
      );
      expect(dao.putCalls.single, id);
    });
  });
}
