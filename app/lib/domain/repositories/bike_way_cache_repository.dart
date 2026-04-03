import 'package:sofia_bike_nav/domain/entities/bike_way.dart';

abstract interface class BikeWayCacheRepository {
  /// Returns all bike ways stored in the local cache.
  Future<List<BikeWay>> getBikeWays();

  /// Replaces the entire cached bike-way collection with [bikeWays].
  Future<void> saveBikeWays(List<BikeWay> bikeWays);

  /// Removes all cached bike ways.
  Future<void> clearBikeWays();
}
