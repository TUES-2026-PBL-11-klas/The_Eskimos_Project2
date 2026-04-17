import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/api_client.dart';
import '../data/api/backend_api.dart';
import '../data/db/bike_ways_dao.dart';
import '../data/db/cache_db.dart';
import '../data/db/routes_dao.dart';
import '../data/models/bike_profile.dart';
import '../data/repositories/bike_lanes_repository.dart';
import '../data/repositories/geocoding_repository.dart';
import '../data/repositories/routing_repository.dart';
import '../services/location_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final backendApiProvider =
    Provider<BackendApi>((ref) => BackendApi(ref.watch(apiClientProvider)));

final cacheDbProvider = FutureProvider<CacheDb>((ref) => CacheDb.instance());

final routesDaoProvider = FutureProvider<RoutesDao>((ref) async {
  final db = await ref.watch(cacheDbProvider.future);
  return RoutesDao(db);
});

final bikeWaysDaoProvider = FutureProvider<BikeWaysDao>((ref) async {
  final db = await ref.watch(cacheDbProvider.future);
  return BikeWaysDao(db);
});

final routingRepositoryProvider = FutureProvider<RoutingRepository>((ref) async {
  final dao = await ref.watch(routesDaoProvider.future);
  return RoutingRepository(ref.watch(backendApiProvider), dao);
});

final bikeLanesRepositoryProvider =
    FutureProvider<BikeLanesRepository>((ref) async {
  final dao = await ref.watch(bikeWaysDaoProvider.future);
  return BikeLanesRepository(ref.watch(backendApiProvider), dao);
});

final geocodingRepositoryProvider = Provider<GeocodingRepository>(
    (ref) => GeocodingRepository(ref.watch(backendApiProvider)));

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final profilesProvider = FutureProvider<List<BikeProfile>>(
    (ref) => ref.watch(backendApiProvider).listProfiles());

final bikeLanesGeoJsonProvider = FutureProvider<String>((ref) async {
  final repo = await ref.watch(bikeLanesRepositoryProvider.future);
  return repo.load();
});

final currentPositionProvider = StreamProvider<Position>((ref) {
  final loc = ref.watch(locationServiceProvider);
  return loc.positionStream();
});
