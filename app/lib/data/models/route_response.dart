import 'maneuver.dart';

class ElevationSummary {
  const ElevationSummary({
    required this.minElevation,
    required this.maxElevation,
    required this.meanElevation,
  });

  final double minElevation;
  final double maxElevation;
  final double meanElevation;

  factory ElevationSummary.fromJson(Map<String, dynamic> j) => ElevationSummary(
        minElevation: (j['min_elevation'] as num).toDouble(),
        maxElevation: (j['max_elevation'] as num).toDouble(),
        meanElevation: (j['mean_elevation'] as num).toDouble(),
      );
}

class RouteResponseDto {
  const RouteResponseDto({
    required this.distanceKm,
    required this.durationMinutes,
    required this.polyline,
    required this.legs,
    required this.maneuvers,
    required this.warnings,
    this.elevation,
  });

  final double distanceKm;
  final double durationMinutes;
  final String polyline;
  final List<Map<String, dynamic>> legs;
  final List<Maneuver> maneuvers;
  final List<String> warnings;
  final ElevationSummary? elevation;

  factory RouteResponseDto.fromJson(Map<String, dynamic> j) => RouteResponseDto(
        distanceKm: (j['distance_km'] as num).toDouble(),
        durationMinutes: (j['duration_minutes'] as num).toDouble(),
        polyline: j['polyline'] as String,
        legs: ((j['legs'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        maneuvers: ((j['maneuvers'] as List?) ?? const [])
            .map((e) => Maneuver.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        warnings: ((j['warnings'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        elevation: j['elevation'] == null
            ? null
            : ElevationSummary.fromJson(
                Map<String, dynamic>.from(j['elevation'] as Map)),
      );
}
