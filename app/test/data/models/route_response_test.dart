import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/models/route_response.dart';

void main() {
  group('ElevationSummary', () {
    test('fromJson parses every field', () {
      final e = ElevationSummary.fromJson(const {
        'min_elevation': 500,
        'max_elevation': 700.5,
        'mean_elevation': 612.25,
      });
      expect(e.minElevation, 500.0);
      expect(e.maxElevation, 700.5);
      expect(e.meanElevation, 612.25);
    });
  });

  group('RouteResponseDto', () {
    test('fromJson parses all required and optional fields', () {
      final r = RouteResponseDto.fromJson(const {
        'distance_km': 2.5,
        'duration_minutes': 12.0,
        'polyline': 'abc',
        'legs': [
          {'foo': 'bar'},
        ],
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
        'warnings': ['careful'],
        'elevation': {
          'min_elevation': 100,
          'max_elevation': 200,
          'mean_elevation': 150,
        },
      });
      expect(r.distanceKm, 2.5);
      expect(r.durationMinutes, 12.0);
      expect(r.polyline, 'abc');
      expect(r.legs, hasLength(1));
      expect(r.legs.first['foo'], 'bar');
      expect(r.maneuvers, hasLength(1));
      expect(r.maneuvers.first.instruction, 'Go');
      expect(r.warnings, ['careful']);
      expect(r.elevation, isNotNull);
      expect(r.elevation!.meanElevation, 150.0);
    });

    test('fromJson tolerates missing optional fields', () {
      final r = RouteResponseDto.fromJson(const {
        'distance_km': 0,
        'duration_minutes': 0,
        'polyline': '',
      });
      expect(r.legs, isEmpty);
      expect(r.maneuvers, isEmpty);
      expect(r.warnings, isEmpty);
      expect(r.elevation, isNull);
    });

    test('fromJson stringifies warnings', () {
      final r = RouteResponseDto.fromJson(const {
        'distance_km': 0,
        'duration_minutes': 0,
        'polyline': '',
        'warnings': [1, 'two'],
      });
      expect(r.warnings, ['1', 'two']);
    });
  });
}
