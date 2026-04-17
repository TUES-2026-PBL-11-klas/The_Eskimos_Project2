import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/db/bike_ways_dao.dart';

void main() {
  group('BikeWaysRecord', () {
    test('stores all constructor arguments', () {
      const r = BikeWaysRecord(
        geojson: '{"type":"FeatureCollection","features":[]}',
        fetchedAt: 1700000000,
        versionHash: 'abc123',
      );
      expect(r.geojson, isNotEmpty);
      expect(r.fetchedAt, 1700000000);
      expect(r.versionHash, 'abc123');
    });
  });
}
