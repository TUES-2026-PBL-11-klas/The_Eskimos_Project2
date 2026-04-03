import 'package:sofia_bike_nav/data/datasources/local/bike_way_local_datasource.dart';
import 'package:sofia_bike_nav/domain/entities/bike_way.dart';
import 'package:sofia_bike_nav/domain/repositories/bike_way_cache_repository.dart';

class BikeWayCacheRepositoryImpl implements BikeWayCacheRepository {
  final BikeWayLocalDatasource _datasource;

  BikeWayCacheRepositoryImpl({BikeWayLocalDatasource? datasource})
      : _datasource = datasource ?? BikeWayLocalDatasource();

  @override
  Future<List<BikeWay>> getBikeWays() => _datasource.getBikeWays();

  @override
  Future<void> saveBikeWays(List<BikeWay> bikeWays) =>
      _datasource.saveBikeWays(bikeWays);

  @override
  Future<void> clearBikeWays() => _datasource.clearBikeWays();
}
