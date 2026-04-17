import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/models/lat_lng_point.dart';

void main() {
  group('LatLngPoint', () {
    test('constructor stores lat and lon', () {
      const p = LatLngPoint(42.6977, 23.3219);
      expect(p.lat, 42.6977);
      expect(p.lon, 23.3219);
    });

    test('toJson produces expected map', () {
      const p = LatLngPoint(1.5, -2.25);
      expect(p.toJson(), {'lat': 1.5, 'lon': -2.25});
    });

    test('fromJson parses double values', () {
      final p = LatLngPoint.fromJson({'lat': 42.1, 'lon': 23.2});
      expect(p.lat, 42.1);
      expect(p.lon, 23.2);
    });

    test('fromJson coerces integer values to double', () {
      final p = LatLngPoint.fromJson({'lat': 42, 'lon': 23});
      expect(p.lat, 42.0);
      expect(p.lon, 23.0);
      expect(p.lat, isA<double>());
      expect(p.lon, isA<double>());
    });

    test('round-trips through JSON', () {
      const original = LatLngPoint(42.5, 23.7);
      final clone = LatLngPoint.fromJson(original.toJson());
      expect(clone.lat, original.lat);
      expect(clone.lon, original.lon);
    });
  });
}
