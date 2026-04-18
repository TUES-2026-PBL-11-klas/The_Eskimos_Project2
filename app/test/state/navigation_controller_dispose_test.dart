import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sofia_bike_nav/data/models/maneuver.dart';
import 'package:sofia_bike_nav/data/models/route_response.dart';
import 'package:sofia_bike_nav/state/navigation_controller.dart';

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

RouteResponseDto _route() => RouteResponseDto(
      distanceKm: 0.222,
      durationMinutes: 1.0,
      polyline: _encodePolyline6(const [
        LatLng(0.0, 0.0),
        LatLng(0.0, 0.001),
        LatLng(0.0, 0.002),
      ]),
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

void main() {
  group('NavigationController dispose semantics', () {
    test('stop() after start() fully clears tracker — next update no-ops', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final ctl = c.read(navigationControllerProvider.notifier);

      ctl.start(_route());
      ctl.stop();

      // Without the tracker guard, this path would NPE.
      ctl.updatePosition(const LatLng(0.0, 0.0005));
      expect(c.read(navigationControllerProvider), isNull);
    });

    test('container.dispose() does not throw for active navigation', () {
      final c = ProviderContainer();
      c.read(navigationControllerProvider.notifier).start(_route());
      expect(c.dispose, returnsNormally);
    });

    test('repeated start/stop cycles produce clean state each time', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final ctl = c.read(navigationControllerProvider.notifier);

      for (var i = 0; i < 3; i++) {
        ctl.start(_route());
        expect(c.read(navigationControllerProvider), isNotNull);
        ctl.stop();
        expect(c.read(navigationControllerProvider), isNull);
      }
    });
  });
}
