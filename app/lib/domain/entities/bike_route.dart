import 'package:sofia_bike_nav/domain/entities/location.dart';

class BikeRoute {
  final String id;
  final Location origin;
  final Location destination;

  /// Ordered list of [lat, lng] coordinate pairs along the route.
  final List<List<double>> waypoints;

  /// Total route distance in metres.
  final double distanceMetres;

  /// Estimated travel time in seconds.
  final double durationSeconds;

  final DateTime createdAt;

  const BikeRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.waypoints,
    required this.distanceMetres,
    required this.durationSeconds,
    required this.createdAt,
  });
}
