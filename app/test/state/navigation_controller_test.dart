import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sofia_bike_nav/data/models/maneuver.dart';
import 'package:sofia_bike_nav/data/models/route_response.dart';
import 'package:sofia_bike_nav/services/route_progress_tracker.dart';
import 'package:sofia_bike_nav/state/navigation_controller.dart';

// Encoder lifted from polyline6 test. Generates a known polyline6 string for
// an east-ward track along the equator.
String _encodePolyline6(List<LatLng> pts) {
  final factor = 1000000;
  final sb = StringBuffer();
  int prevLat = 0;
  int prevLon = 0;
  for (final p in pts) {
    final lat = (p.latitude * factor).round();
    final lon = (p.longitude * factor).round();
    _writeVarint(sb, lat - prevLat);
    _writeVarint(sb, lon - prevLon);
    prevLat = lat;
    prevLon = lon;
  }
  return sb.toString();
}

void _writeVarint(StringBuffer sb, int value) {
  int v = value < 0 ? ~(value << 1) : (value << 1);
  while (v >= 0x20) {
    sb.writeCharCode((0x20 | (v & 0x1f)) + 63);
    v >>= 5;
  }
  sb.writeCharCode(v + 63);
}

RouteResponseDto _sampleRoute() {
  const pts = [
    LatLng(0.0, 0.0),
    LatLng(0.0, 0.001),
    LatLng(0.0, 0.002),
  ];
  return RouteResponseDto(
    distanceKm: 0.222,
    durationMinutes: 1.0,
    polyline: _encodePolyline6(pts),
    maneuvers: const [
      Maneuver(
        instruction: 'Start',
        streetNames: [],
        lengthKm: 0.222,
        timeSeconds: 60,
        type: 1,
        beginShapeIndex: 0,
        endShapeIndex: 2,
      ),
    ],
  );
}

void main() {
  late ProviderContainer container;
  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  NavigationController notifier() =>
      container.read(navigationControllerProvider.notifier);

  group('NavigationController', () {
    test('starts with null state', () {
      expect(container.read(navigationControllerProvider), isNull);
    });

    test('start sets state with decoded shape and no progress yet', () {
      final route = _sampleRoute();
      notifier().start(route);
      final s = container.read(navigationControllerProvider);
      expect(s, isNotNull);
      expect(s!.route, route);
      expect(s.shape, isNotEmpty);
      expect(s.progress, isNull);
    });

    test('updatePosition populates progress', () {
      final route = _sampleRoute();
      notifier().start(route);
      notifier().updatePosition(const LatLng(0.0, 0.0005));
      final s = container.read(navigationControllerProvider);
      expect(s?.progress, isNotNull);
      expect(s!.progress!.snappedIndex, greaterThanOrEqualTo(0));
    });

    test('updatePosition is a no-op when state is null', () {
      notifier().updatePosition(const LatLng(0.0, 0.0));
      expect(container.read(navigationControllerProvider), isNull);
    });

    test('stop clears state', () {
      notifier().start(_sampleRoute());
      expect(container.read(navigationControllerProvider), isNotNull);
      notifier().stop();
      expect(container.read(navigationControllerProvider), isNull);
    });

    test('updatePosition after stop is a no-op', () {
      notifier().start(_sampleRoute());
      notifier().stop();
      notifier().updatePosition(const LatLng(0.0, 0.0));
      expect(container.read(navigationControllerProvider), isNull);
    });
  });

  group('NavigationState.copyWith', () {
    test('replaces progress only', () {
      final route = _sampleRoute();
      notifier().start(route);
      final initial = container.read(navigationControllerProvider)!;
      final next = initial.copyWith(
        progress: const RouteProgress(
          snappedIndex: 0,
          currentManeuver: 0,
          distanceToNextManeuverM: 0,
          remainingDurationSeconds: 0,
          remainingDistanceM: 0,
          offRouteM: 0,
        ),
      );
      expect(next.route, initial.route);
      expect(next.shape, initial.shape);
      expect(next.progress, isNotNull);
    });

    test('returning progress: null keeps existing progress', () {
      final route = _sampleRoute();
      notifier().start(route);
      notifier().updatePosition(const LatLng(0.0, 0.0005));
      final before = container.read(navigationControllerProvider)!;
      final after = before.copyWith();
      expect(after.progress, before.progress);
    });
  });
}

