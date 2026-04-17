import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:sofia_bike_nav/data/models/maneuver.dart';
import 'package:sofia_bike_nav/services/route_progress_tracker.dart';

void main() {
  group('RouteProgressTracker', () {
    // An east-ward track: three segments going east along the equator, so
    // longitude differences translate directly into meters (≈111 km/deg).
    final shape = [
      const LatLng(0.0, 0.0),
      const LatLng(0.0, 0.001), // ≈111 m
      const LatLng(0.0, 0.002), // ≈222 m
      const LatLng(0.0, 0.003), // ≈333 m
    ];

    const maneuvers = [
      Maneuver(
        instruction: 'Start',
        streetNames: [],
        lengthKm: 0.222,
        timeSeconds: 60,
        type: 1,
        beginShapeIndex: 0,
        endShapeIndex: 2,
      ),
      Maneuver(
        instruction: 'Finish',
        streetNames: [],
        lengthKm: 0.111,
        timeSeconds: 30,
        type: 4,
        beginShapeIndex: 2,
        endShapeIndex: 3,
      ),
    ];

    test('snaps to start of track when position is at origin', () {
      final tracker = RouteProgressTracker(shape: shape, maneuvers: maneuvers);
      final p = tracker.update(const LatLng(0.0, 0.0));
      expect(p.snappedIndex, 0);
      expect(p.offRouteM, closeTo(0.0, 1e-3));
      expect(p.currentManeuver, 0);
      expect(p.remainingDistanceM, greaterThan(0));
    });

    test('snaps to middle segment when position is between shape points', () {
      final tracker = RouteProgressTracker(shape: shape, maneuvers: maneuvers);
      final p = tracker.update(const LatLng(0.0, 0.0015));
      // 0.0015 lies between shape[1] (0.001) and shape[2] (0.002) → seg idx 1
      expect(p.snappedIndex, 1);
      expect(p.offRouteM, lessThan(1.0));
    });

    test('off-route distance grows when away from track', () {
      final tracker = RouteProgressTracker(shape: shape, maneuvers: maneuvers);
      // Move ~1 km north of the track.
      final p = tracker.update(const LatLng(0.01, 0.0015));
      expect(p.offRouteM, greaterThan(500.0));
    });

    test('remaining distance decreases as we progress', () {
      final tracker = RouteProgressTracker(shape: shape, maneuvers: maneuvers);
      final start = tracker.update(const LatLng(0.0, 0.0));
      final mid = tracker.update(const LatLng(0.0, 0.0015));
      expect(mid.remainingDistanceM, lessThan(start.remainingDistanceM));
    });

    test('remaining duration never exceeds total duration', () {
      final tracker = RouteProgressTracker(shape: shape, maneuvers: maneuvers);
      final p = tracker.update(const LatLng(0.0, 0.0));
      final totalSeconds =
          maneuvers.fold<double>(0, (a, m) => a + m.timeSeconds);
      expect(p.remainingDurationSeconds,
          lessThanOrEqualTo(totalSeconds + 1e-6));
    });

    test('selects second maneuver when past first maneuver range', () {
      final tracker = RouteProgressTracker(shape: shape, maneuvers: maneuvers);
      // Position within second maneuver range (shape index 2..3).
      final p = tracker.update(const LatLng(0.0, 0.0025));
      expect(p.snappedIndex, 2);
      expect(p.currentManeuver, 1);
    });

    test('distance to next maneuver sums to end of shape when no next', () {
      final tracker = RouteProgressTracker(shape: shape, maneuvers: maneuvers);
      final p = tracker.update(const LatLng(0.0, 0.003));
      // snappedIndex clamps to last segment, which is inside final maneuver.
      expect(p.currentManeuver, 1);
      // With no next maneuver, distToNext walks remaining segments to end of
      // shape — bounded by the final segment length (~111 m).
      expect(p.distanceToNextManeuverM, lessThan(200.0));
    });

    test('handles tracks with zero-length segment without crashing', () {
      final dupShape = [
        const LatLng(0.0, 0.0),
        const LatLng(0.0, 0.0), // duplicate
        const LatLng(0.0, 0.001),
      ];
      const ms = [
        Maneuver(
          instruction: 'Go',
          streetNames: [],
          lengthKm: 0.111,
          timeSeconds: 30,
          type: 8,
          beginShapeIndex: 0,
          endShapeIndex: 2,
        ),
      ];
      final tracker = RouteProgressTracker(shape: dupShape, maneuvers: ms);
      final p = tracker.update(const LatLng(0.0, 0.0));
      expect(p.snappedIndex, greaterThanOrEqualTo(0));
      expect(p.offRouteM.isFinite, isTrue);
    });
  });

  group('RouteProgress', () {
    test('stores all constructor arguments', () {
      const p = RouteProgress(
        snappedIndex: 2,
        currentManeuver: 1,
        distanceToNextManeuverM: 50.0,
        remainingDurationSeconds: 120.0,
        remainingDistanceM: 800.0,
        offRouteM: 3.2,
      );
      expect(p.snappedIndex, 2);
      expect(p.currentManeuver, 1);
      expect(p.distanceToNextManeuverM, 50.0);
      expect(p.remainingDurationSeconds, 120.0);
      expect(p.remainingDistanceM, 800.0);
      expect(p.offRouteM, 3.2);
    });
  });
}
