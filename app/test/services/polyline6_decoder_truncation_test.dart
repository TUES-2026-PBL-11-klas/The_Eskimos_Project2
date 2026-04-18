import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sofia_bike_nav/services/polyline6_decoder.dart';

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

void main() {
  group('decodePolyline6 truncation handling', () {
    test('truncated mid-latitude returns empty without throwing', () {
      // Build a valid 2-point encoding, then chop off the last byte.
      const pts = [LatLng(42.6977, 23.3219), LatLng(42.7000, 23.3250)];
      final encoded = _encodePolyline6(pts);
      final truncated = encoded.substring(0, encoded.length - 1);
      expect(() => decodePolyline6(truncated), returnsNormally);
    });

    test('truncated mid-longitude returns only valid prefix', () {
      const pts = [LatLng(42.6977, 23.3219), LatLng(42.7000, 23.3250)];
      final encoded = _encodePolyline6(pts);
      // First pair decodes fine; cut inside the second pair.
      final halfway = encoded.length ~/ 2 + 1;
      final truncated = encoded.substring(0, halfway);
      final decoded = decodePolyline6(truncated);
      // Should decode at least one point without throwing.
      expect(decoded, isA<List<LatLng>>());
    });

    test('single-byte garbage input does not throw', () {
      expect(() => decodePolyline6('?'), returnsNormally);
    });

    test('empty string returns empty list', () {
      expect(decodePolyline6(''), isEmpty);
    });
  });
}
