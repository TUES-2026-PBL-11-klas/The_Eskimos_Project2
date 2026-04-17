import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sofia_bike_nav/services/polyline6_decoder.dart';

// Reference encoder used only in tests to produce known-good fixtures.
String _encodePolyline6(List<LatLng> pts, {int precision = 6}) {
  final factor = _pow10(precision);
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

int _pow10(int n) {
  int v = 1;
  for (int i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}

void _expectLatLngClose(LatLng a, LatLng b,
    {double tol = 1e-5, String? reason}) {
  expect(a.latitude, closeTo(b.latitude, tol), reason: reason);
  expect(a.longitude, closeTo(b.longitude, tol), reason: reason);
}

void main() {
  group('decodePolyline6', () {
    test('round-trips single point', () {
      const pts = [LatLng(42.6977, 23.3219)];
      final encoded = _encodePolyline6(pts);
      final decoded = decodePolyline6(encoded);
      expect(decoded, hasLength(1));
      _expectLatLngClose(decoded[0], pts[0]);
    });

    test('round-trips multi-point track', () {
      const pts = [
        LatLng(42.69770, 23.32190),
        LatLng(42.69800, 23.32200),
        LatLng(42.69830, 23.32250),
      ];
      final encoded = _encodePolyline6(pts);
      final decoded = decodePolyline6(encoded);
      expect(decoded, hasLength(pts.length));
      for (var i = 0; i < pts.length; i++) {
        _expectLatLngClose(decoded[i], pts[i]);
      }
    });

    test('handles negative deltas (going south-west)', () {
      const pts = [
        LatLng(10.0, 20.0),
        LatLng(9.5, 19.5),
        LatLng(9.0, 19.0),
      ];
      final encoded = _encodePolyline6(pts);
      final decoded = decodePolyline6(encoded);
      for (var i = 0; i < pts.length; i++) {
        _expectLatLngClose(decoded[i], pts[i]);
      }
    });

    test('empty input yields empty output', () {
      expect(decodePolyline6(''), isEmpty);
    });

    test('precision parameter scales coordinates', () {
      // Encode with precision 5 and decode with same precision.
      const pts = [LatLng(1.0, 2.0), LatLng(1.5, 2.5)];
      final enc = _encodePolyline6(pts, precision: 5);
      final decoded = decodePolyline6(enc, precision: 5);
      for (var i = 0; i < pts.length; i++) {
        _expectLatLngClose(decoded[i], pts[i], tol: 1e-4);
      }
    });
  });
}
