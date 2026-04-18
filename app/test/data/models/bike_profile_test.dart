import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/models/bike_profile.dart';

void main() {
  group('BikeProfileId', () {
    test('each enum carries its string value', () {
      expect(BikeProfileId.cityBike.value, 'city_bike');
      expect(BikeProfileId.mountainBike.value, 'mountain_bike');
      expect(BikeProfileId.electricBike.value, 'electric_bike');
    });

    test('fromValue returns matching id', () {
      expect(BikeProfileId.fromValue('city_bike'), BikeProfileId.cityBike);
      expect(
        BikeProfileId.fromValue('mountain_bike'),
        BikeProfileId.mountainBike,
      );
      expect(
        BikeProfileId.fromValue('electric_bike'),
        BikeProfileId.electricBike,
      );
    });

    test('fromValue throws ArgumentError on unknown input', () {
      expect(() => BikeProfileId.fromValue('unknown'), throwsArgumentError);
      expect(() => BikeProfileId.fromValue(''), throwsArgumentError);
    });
  });

  group('BikeProfile', () {
    const sampleJson = {
      'name': 'mountain_bike',
      'display_name': 'Mountain Bike',
      'description': 'Off-road capable',
      'bicycle_type': 'mountain',
      'use_roads': 0.3,
      'use_hills': 0.8,
      'cycling_speed': 18,
    };

    test('fromJson parses every field', () {
      final p = BikeProfile.fromJson(Map<String, dynamic>.from(sampleJson));
      expect(p.name, 'mountain_bike');
      expect(p.displayName, 'Mountain Bike');
      expect(p.description, 'Off-road capable');
      expect(p.bicycleType, 'mountain');
      expect(p.useRoads, 0.3);
      expect(p.useHills, 0.8);
      expect(p.cyclingSpeed, 18.0);
    });

    test('id resolves from the name field', () {
      final p = BikeProfile.fromJson(Map<String, dynamic>.from(sampleJson));
      expect(p.id, BikeProfileId.mountainBike);
    });

    test('id throws on unknown name', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['name'] = 'gravity_bike';
      final p = BikeProfile.fromJson(json);
      expect(() => p.id, throwsArgumentError);
    });

    test('integer numeric fields get coerced to double', () {
      final json = Map<String, dynamic>.from(sampleJson);
      json['use_roads'] = 1;
      json['use_hills'] = 0;
      final p = BikeProfile.fromJson(json);
      expect(p.useRoads, 1.0);
      expect(p.useHills, 0.0);
    });
  });
}
