import 'dart:math' as math;

import 'package:maplibre_gl/maplibre_gl.dart';

import '../data/models/maneuver.dart';

class RouteProgress {
  const RouteProgress({
    required this.snappedIndex,
    required this.currentManeuver,
    required this.distanceToNextManeuverM,
    required this.remainingDurationSeconds,
    required this.remainingDistanceM,
    required this.offRouteM,
  });

  final int snappedIndex;
  final int currentManeuver;
  final double distanceToNextManeuverM;
  final double remainingDurationSeconds;
  final double remainingDistanceM;
  final double offRouteM;
}

class RouteProgressTracker {
  RouteProgressTracker({
    required this.shape,
    required this.maneuvers,
  }) : _segmentLengths = _computeSegmentLengths(shape),
       _totalDurationSeconds =
           maneuvers.fold<double>(0, (a, m) => a + m.timeSeconds);

  final List<LatLng> shape;
  final List<Maneuver> maneuvers;
  final List<double> _segmentLengths; // length[i] = dist(shape[i], shape[i+1])
  final double _totalDurationSeconds;

  RouteProgress update(LatLng position) {
    // Find nearest segment by projecting position onto each shape segment.
    int bestIdx = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < shape.length - 1; i++) {
      final d = _distancePointToSegment(position, shape[i], shape[i + 1]);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }

    // Identify current maneuver = one whose [begin, end) contains bestIdx.
    int currentManeuver = 0;
    for (int i = 0; i < maneuvers.length; i++) {
      if (bestIdx >= maneuvers[i].beginShapeIndex &&
          bestIdx < maneuvers[i].endShapeIndex) {
        currentManeuver = i;
        break;
      }
      if (i == maneuvers.length - 1) currentManeuver = i;
    }

    // Distance along shape from bestIdx+1 to start of next maneuver.
    double distToNext = 0;
    final nextIdx = currentManeuver + 1 < maneuvers.length
        ? maneuvers[currentManeuver + 1].beginShapeIndex
        : shape.length - 1;
    for (int i = bestIdx; i < nextIdx && i < _segmentLengths.length; i++) {
      distToNext += _segmentLengths[i];
    }

    // Remaining distance = all segments from bestIdx to end.
    double remainingDistance = 0;
    for (int i = bestIdx; i < _segmentLengths.length; i++) {
      remainingDistance += _segmentLengths[i];
    }

    // Remaining duration: sum time of current + upcoming maneuvers,
    // prorated by how much of the current maneuver is left.
    double remainingDuration = 0;
    for (int i = currentManeuver + 1; i < maneuvers.length; i++) {
      remainingDuration += maneuvers[i].timeSeconds;
    }
    final currM = maneuvers[currentManeuver];
    final currLen = (currM.lengthKm * 1000.0);
    if (currLen > 0 && currM.endShapeIndex > currM.beginShapeIndex) {
      double currLeft = 0;
      for (int i = bestIdx;
          i < currM.endShapeIndex && i < _segmentLengths.length;
          i++) {
        currLeft += _segmentLengths[i];
      }
      remainingDuration += currM.timeSeconds * (currLeft / currLen);
    }

    return RouteProgress(
      snappedIndex: bestIdx,
      currentManeuver: currentManeuver,
      distanceToNextManeuverM: distToNext,
      remainingDurationSeconds:
          remainingDuration.clamp(0, _totalDurationSeconds),
      remainingDistanceM: remainingDistance,
      offRouteM: bestDist,
    );
  }

  static List<double> _computeSegmentLengths(List<LatLng> shape) {
    final out = <double>[];
    for (int i = 0; i < shape.length - 1; i++) {
      out.add(_haversine(shape[i], shape[i + 1]));
    }
    return out;
  }
}

/// Great-circle distance in meters.
double _haversine(LatLng a, LatLng b) {
  const r = 6371000.0;
  final dLat = _deg(b.latitude - a.latitude);
  final dLon = _deg(b.longitude - a.longitude);
  final la1 = _deg(a.latitude);
  final la2 = _deg(b.latitude);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(la1) * math.cos(la2) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return 2 * r * math.asin(math.min(1.0, math.sqrt(h)));
}

double _deg(double v) => v * math.pi / 180.0;

/// Approximate point-to-segment distance on a small scale using an
/// equirectangular projection local to the segment midpoint. For segments
/// of a few meters this is accurate to well under 1 m.
double _distancePointToSegment(LatLng p, LatLng a, LatLng b) {
  const r = 6371000.0;
  final lat0 = _deg((a.latitude + b.latitude) / 2);
  double toX(LatLng pt) => r * _deg(pt.longitude) * math.cos(lat0);
  double toY(LatLng pt) => r * _deg(pt.latitude);
  final ax = toX(a), ay = toY(a);
  final bx = toX(b), by = toY(b);
  final px = toX(p), py = toY(p);
  final dx = bx - ax, dy = by - ay;
  final len2 = dx * dx + dy * dy;
  if (len2 == 0) {
    final ex = px - ax, ey = py - ay;
    return math.sqrt(ex * ex + ey * ey);
  }
  double t = ((px - ax) * dx + (py - ay) * dy) / len2;
  t = t.clamp(0.0, 1.0);
  final cx = ax + t * dx, cy = ay + t * dy;
  final ex = px - cx, ey = py - cy;
  return math.sqrt(ex * ex + ey * ey);
}
