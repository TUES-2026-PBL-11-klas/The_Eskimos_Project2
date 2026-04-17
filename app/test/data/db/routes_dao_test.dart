import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/db/routes_dao.dart';
import 'package:sofia_bike_nav/data/models/bike_profile.dart';
import 'package:sofia_bike_nav/data/models/lat_lng_point.dart';

void main() {
  group('RoutesDao.idFor', () {
    test('formats both points to 5 decimal places and appends profile', () {
      final id = RoutesDao.idFor(
        const LatLngPoint(42.6977, 23.3219),
        const LatLngPoint(42.7001, 23.3450),
        BikeProfileId.cityBike,
      );
      expect(id, '42.69770,23.32190->42.70010,23.34500:city_bike');
    });

    test('rounds additional decimals to 5 places', () {
      final id = RoutesDao.idFor(
        const LatLngPoint(1.123456789, 2.987654321),
        const LatLngPoint(3.111111111, 4.222222222),
        BikeProfileId.mountainBike,
      );
      expect(id, '1.12346,2.98765->3.11111,4.22222:mountain_bike');
    });

    test('is deterministic for equal inputs', () {
      final a = RoutesDao.idFor(
        const LatLngPoint(1.0, 2.0),
        const LatLngPoint(3.0, 4.0),
        BikeProfileId.electricBike,
      );
      final b = RoutesDao.idFor(
        const LatLngPoint(1.0, 2.0),
        const LatLngPoint(3.0, 4.0),
        BikeProfileId.electricBike,
      );
      expect(a, b);
    });

    test('profile affects id', () {
      final a = RoutesDao.idFor(
        const LatLngPoint(1, 2),
        const LatLngPoint(3, 4),
        BikeProfileId.cityBike,
      );
      final b = RoutesDao.idFor(
        const LatLngPoint(1, 2),
        const LatLngPoint(3, 4),
        BikeProfileId.mountainBike,
      );
      expect(a, isNot(b));
    });
  });
}
