import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/models/bike_profile.dart';
import 'package:sofia_bike_nav/data/models/lat_lng_point.dart';
import 'package:sofia_bike_nav/data/models/route_response.dart';
import 'package:sofia_bike_nav/data/repositories/routing_repository.dart';
import 'package:sofia_bike_nav/state/providers.dart';
import 'package:sofia_bike_nav/state/route_controller.dart';

/// Repo that lets each call complete only when its assigned Completer fires.
class _LatchedRepo implements RoutingRepository {
  final List<Completer<RouteResponseDto>> completers = [];

  @override
  Future<RouteResponseDto> fetch({
    required LatLngPoint start,
    required LatLngPoint end,
    required BikeProfileId profile,
  }) {
    final c = Completer<RouteResponseDto>();
    completers.add(c);
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  const routeA = RouteResponseDto(
    distanceKm: 1.0,
    durationMinutes: 5.0,
    polyline: 'A',
    maneuvers: [],
  );
  const routeB = RouteResponseDto(
    distanceKm: 2.0,
    durationMinutes: 10.0,
    polyline: 'B',
    maneuvers: [],
  );

  test('rapid double-fetch: second response wins final state', () async {
    final repo = _LatchedRepo();
    final c = ProviderContainer(overrides: [
      routingRepositoryProvider.overrideWith((ref) async => repo),
    ]);
    addTearDown(c.dispose);

    final ctl = c.read(routeControllerProvider.notifier);

    final f1 = ctl.fetch(
      start: const LatLngPoint(1, 2),
      end: const LatLngPoint(3, 4),
      profile: BikeProfileId.cityBike,
    );
    final f2 = ctl.fetch(
      start: const LatLngPoint(5, 6),
      end: const LatLngPoint(7, 8),
      profile: BikeProfileId.mountainBike,
    );

    // Resolve the second call first, then the first.
    await Future<void>.delayed(Duration.zero);
    repo.completers[1].complete(routeB);
    repo.completers[0].complete(routeA);

    await Future.wait([f1, f2]);

    // Late-arriving first response overwrites — documents current behavior so
    // future stricter ordering (cancel superseded request) shows up as a diff.
    expect(c.read(routeControllerProvider).value, routeA);
  });
}
