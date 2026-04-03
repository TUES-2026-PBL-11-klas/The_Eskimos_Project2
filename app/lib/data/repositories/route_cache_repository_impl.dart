import 'package:sofia_bike_nav/data/datasources/local/route_local_datasource.dart';
import 'package:sofia_bike_nav/domain/entities/bike_route.dart';
import 'package:sofia_bike_nav/domain/entities/location.dart';
import 'package:sofia_bike_nav/domain/repositories/route_cache_repository.dart';

class RouteCacheRepositoryImpl implements RouteCacheRepository {
  final RouteLocalDatasource _datasource;

  RouteCacheRepositoryImpl({RouteLocalDatasource? datasource})
      : _datasource = datasource ?? RouteLocalDatasource();

  @override
  Future<BikeRoute?> getRoute(
    Location origin,
    Location destination, {
    double toleranceDeg = 0.0001,
  }) =>
      _datasource.getRoute(origin, destination, toleranceDeg: toleranceDeg);

  @override
  Future<void> saveRoute(BikeRoute route) => _datasource.saveRoute(route);

  @override
  Future<void> clearRoutes() => _datasource.clearRoutes();
}
