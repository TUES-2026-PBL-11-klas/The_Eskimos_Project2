import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/models/bike_profile.dart';
import 'package:sofia_bike_nav/data/models/lat_lng_point.dart';
import 'package:sofia_bike_nav/data/models/route_request.dart';

void main() {
  group('RouteRequestDto', () {
    test('uses default values', () {
      const req = RouteRequestDto(
        start: LatLngPoint(1.0, 2.0),
        end: LatLngPoint(3.0, 4.0),
        profile: BikeProfileId.cityBike,
      );
      expect(req.avoidDangerous, true);
      expect(req.language, 'bg-BG');
      expect(req.extraAvoidPolygons, isEmpty);
    });

    test('toJson emits the default payload', () {
      const req = RouteRequestDto(
        start: LatLngPoint(1.0, 2.0),
        end: LatLngPoint(3.0, 4.0),
        profile: BikeProfileId.electricBike,
      );
      final j = req.toJson();
      expect(j['start'], {'lat': 1.0, 'lon': 2.0});
      expect(j['end'], {'lat': 3.0, 'lon': 4.0});
      expect(j['profile'], 'electric_bike');
      expect(j['avoid_dangerous'], true);
      expect(j['include_elevation'], false);
      expect(j['language'], 'bg-BG');
      expect(j['extra_avoid_polygons'], const []);
    });

    test('toJson serialises nested polygons', () {
      const req = RouteRequestDto(
        start: LatLngPoint(0, 0),
        end: LatLngPoint(1, 1),
        profile: BikeProfileId.mountainBike,
        avoidDangerous: false,
        language: 'en-US',
        extraAvoidPolygons: [
          [LatLngPoint(0, 0), LatLngPoint(0, 1), LatLngPoint(1, 1)],
        ],
      );
      final j = req.toJson();
      expect(j['avoid_dangerous'], false);
      expect(j['include_elevation'], false);
      expect(j['language'], 'en-US');
      expect(j['profile'], 'mountain_bike');
      final polys = j['extra_avoid_polygons'] as List;
      expect(polys, hasLength(1));
      expect(polys.first, hasLength(3));
      expect((polys.first as List).first, {'lat': 0.0, 'lon': 0.0});
    });
  });
}
