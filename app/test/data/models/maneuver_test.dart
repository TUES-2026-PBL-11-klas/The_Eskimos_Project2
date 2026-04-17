import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/models/maneuver.dart';

void main() {
  group('Maneuver', () {
    test('fromJson parses every field', () {
      final m = Maneuver.fromJson(const {
        'instruction': 'Turn right',
        'street_names': ['Vitosha', 'blvd'],
        'length_km': 0.25,
        'time_seconds': 45.0,
        'type': 11,
        'begin_shape_index': 3,
        'end_shape_index': 9,
      });
      expect(m.instruction, 'Turn right');
      expect(m.streetNames, ['Vitosha', 'blvd']);
      expect(m.lengthKm, 0.25);
      expect(m.timeSeconds, 45.0);
      expect(m.type, 11);
      expect(m.beginShapeIndex, 3);
      expect(m.endShapeIndex, 9);
    });

    test('fromJson uses defaults when keys are missing', () {
      final m = Maneuver.fromJson(const {});
      expect(m.instruction, '');
      expect(m.streetNames, const <String>[]);
      expect(m.lengthKm, 0.0);
      expect(m.timeSeconds, 0.0);
      expect(m.type, 0);
      expect(m.beginShapeIndex, 0);
      expect(m.endShapeIndex, 0);
    });

    test('fromJson tolerates nulls for optional keys', () {
      final m = Maneuver.fromJson(const {
        'instruction': null,
        'street_names': null,
        'length_km': null,
        'time_seconds': null,
        'type': null,
        'begin_shape_index': null,
        'end_shape_index': null,
      });
      expect(m.instruction, '');
      expect(m.streetNames, isEmpty);
      expect(m.lengthKm, 0.0);
    });

    test('fromJson stringifies non-string street_names entries', () {
      final m = Maneuver.fromJson(const {
        'street_names': [1, 2, 'three'],
      });
      expect(m.streetNames, ['1', '2', 'three']);
    });

    test('toJson round-trips all fields', () {
      const m = Maneuver(
        instruction: 'Go straight',
        streetNames: ['A', 'B'],
        lengthKm: 1.2,
        timeSeconds: 70,
        type: 8,
        beginShapeIndex: 0,
        endShapeIndex: 4,
      );
      final clone = Maneuver.fromJson(m.toJson());
      expect(clone.instruction, m.instruction);
      expect(clone.streetNames, m.streetNames);
      expect(clone.lengthKm, m.lengthKm);
      expect(clone.timeSeconds, m.timeSeconds);
      expect(clone.type, m.type);
      expect(clone.beginShapeIndex, m.beginShapeIndex);
      expect(clone.endShapeIndex, m.endShapeIndex);
    });
  });
}
