import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/models/route_response.dart';

void main() {
  group('RouteResponseDto', () {
    test('fromJson parses all required and optional fields', () {
      final r = RouteResponseDto.fromJson(const {
        'distance_km': 2.5,
        'duration_minutes': 12.0,
        'polyline': 'abc',
        'maneuvers': [
          {
            'instruction': 'Go',
            'street_names': ['A'],
            'length_km': 1.0,
            'time_seconds': 60,
            'type': 8,
            'begin_shape_index': 0,
            'end_shape_index': 2,
          },
        ],
      });
      expect(r.distanceKm, 2.5);
      expect(r.durationMinutes, 12.0);
      expect(r.polyline, 'abc');
      expect(r.maneuvers, hasLength(1));
      expect(r.maneuvers.first.instruction, 'Go');
    });

    test('fromJson tolerates missing optional fields', () {
      final r = RouteResponseDto.fromJson(const {
        'distance_km': 0,
        'duration_minutes': 0,
        'polyline': '',
      });
      expect(r.maneuvers, isEmpty);
    });
  });
}
