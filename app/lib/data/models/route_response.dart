import 'maneuver.dart';

class RouteResponseDto {
  const RouteResponseDto({
    required this.distanceKm,
    required this.durationMinutes,
    required this.polyline,
    required this.maneuvers,
  });

  final double distanceKm;
  final double durationMinutes;
  final String polyline;
  final List<Maneuver> maneuvers;

  factory RouteResponseDto.fromJson(Map<String, dynamic> j) => RouteResponseDto(
        distanceKm: (j['distance_km'] as num).toDouble(),
        durationMinutes: (j['duration_minutes'] as num).toDouble(),
        polyline: j['polyline'] as String,
        maneuvers: ((j['maneuvers'] as List?) ?? const [])
            .map((e) => Maneuver.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
