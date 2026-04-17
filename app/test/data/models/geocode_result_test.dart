import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/models/geocode_result.dart';

void main() {
  group('GeocodeResult', () {
    test('fromJson parses every field', () {
      final r = GeocodeResult.fromJson(const {
        'label': 'Sofia',
        'lat': 42.6977,
        'lon': 23.3219,
      });
      expect(r.label, 'Sofia');
      expect(r.lat, 42.6977);
      expect(r.lon, 23.3219);
    });

    test('coerces int lat/lon to double', () {
      final r = GeocodeResult.fromJson(const {
        'label': 'Origin',
        'lat': 0,
        'lon': 0,
      });
      expect(r.lat, 0.0);
      expect(r.lon, 0.0);
      expect(r.lat, isA<double>());
      expect(r.lon, isA<double>());
    });

    test('const constructor assigns fields', () {
      const r = GeocodeResult(label: 'X', lat: 1.0, lon: 2.0);
      expect(r.label, 'X');
      expect(r.lat, 1.0);
      expect(r.lon, 2.0);
    });
  });
}
