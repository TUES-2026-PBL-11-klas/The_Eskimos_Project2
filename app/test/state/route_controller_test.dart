import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/db/routes_dao.dart';
import 'package:sofia_bike_nav/data/models/bike_profile.dart';
import 'package:sofia_bike_nav/data/models/lat_lng_point.dart';
import 'package:sofia_bike_nav/data/models/route_response.dart';
import 'package:sofia_bike_nav/data/repositories/routing_repository.dart';
import 'package:sofia_bike_nav/state/providers.dart';
import 'package:sofia_bike_nav/state/route_controller.dart';

class _FakeRoutesDao implements RoutesDao {
  @override
  Future<RouteResponseDto?> get(String id) async => null;
  @override
  Future<void> put(String id, RouteResponseDto r, BikeProfileId p) async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeRoutingRepo implements RoutingRepository {
  _FakeRoutingRepo(this.result, {this.throwError = false});
  final RouteResponseDto result;
  final bool throwError;

  @override
  Future<RouteResponseDto> fetch({
    required LatLngPoint start,
    required LatLngPoint end,
    required BikeProfileId profile,
  }) async {
    if (throwError) throw Exception('boom');
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  const okRoute = RouteResponseDto(
    distanceKm: 1.0,
    durationMinutes: 5.0,
    polyline: 'x',
    maneuvers: [],
  );

  ProviderContainer makeContainer({required RoutingRepository repo}) {
    return ProviderContainer(overrides: [
      routingRepositoryProvider.overrideWith((ref) async => repo),
    ]);
  }

  group('RouteController', () {
    test('initial state is AsyncValue.data(null)', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(routeControllerProvider), const AsyncValue.data(null));
    });

    test('fetch sets loading, then data on success', () async {
      final c = makeContainer(repo: _FakeRoutingRepo(okRoute));
      addTearDown(c.dispose);

      final states = <AsyncValue<RouteResponseDto?>>[];
      c.listen(routeControllerProvider, (_, n) => states.add(n),
          fireImmediately: true);

      await c.read(routeControllerProvider.notifier).fetch(
            start: const LatLngPoint(1, 2),
            end: const LatLngPoint(3, 4),
            profile: BikeProfileId.cityBike,
          );

      expect(states.first, const AsyncValue.data(null));
      expect(states.any((s) => s.isLoading), isTrue);
      expect(states.last.value, okRoute);
    });

    test('fetch sets error state on failure', () async {
      final c = makeContainer(
        repo: _FakeRoutingRepo(okRoute, throwError: true),
      );
      addTearDown(c.dispose);

      await c.read(routeControllerProvider.notifier).fetch(
            start: const LatLngPoint(1, 2),
            end: const LatLngPoint(3, 4),
            profile: BikeProfileId.cityBike,
          );

      final s = c.read(routeControllerProvider);
      expect(s.hasError, isTrue);
    });

    test('clear resets state to data(null)', () async {
      final c = makeContainer(repo: _FakeRoutingRepo(okRoute));
      addTearDown(c.dispose);

      await c.read(routeControllerProvider.notifier).fetch(
            start: const LatLngPoint(1, 2),
            end: const LatLngPoint(3, 4),
            profile: BikeProfileId.cityBike,
          );
      expect(c.read(routeControllerProvider).value, okRoute);

      c.read(routeControllerProvider.notifier).clear();
      expect(c.read(routeControllerProvider), const AsyncValue.data(null));
    });
  });

  group('_FakeRoutesDao sanity', () {
    test('implements RoutesDao interface without sqflite', () async {
      final dao = _FakeRoutesDao();
      expect(await dao.get('x'), isNull);
      await dao.put('x', okRoute, BikeProfileId.cityBike);
    });
  });
}
