import 'package:sofia_bike_nav/domain/entities/bike_route.dart';
import 'package:sofia_bike_nav/domain/entities/location.dart';

abstract interface class RouteCacheRepository {
  /// Returns a cached route whose origin and destination match [origin] and
  /// [destination] within [toleranceDeg] degrees, or `null` if no entry exists.
  Future<BikeRoute?> getRoute(
    Location origin,
    Location destination, {
    double toleranceDeg = 0.0001,
  });

  /// Persists [route] so that it can be retrieved later.
  Future<void> saveRoute(BikeRoute route);

  /// Removes all cached routes.
  Future<void> clearRoutes();
}
