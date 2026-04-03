import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sofia_bike_nav/data/datasources/local/database_helper.dart';
import 'package:sofia_bike_nav/data/datasources/local/route_local_datasource.dart';
import 'package:sofia_bike_nav/domain/entities/bike_route.dart';
import 'package:sofia_bike_nav/domain/entities/location.dart';

void main() {
  late DatabaseHelper dbHelper;
  late RouteLocalDatasource datasource;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forPath(':memory:');
    datasource = RouteLocalDatasource(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  BikeRoute _buildRoute({
    String id = 'route-1',
    double originLat = 42.698,
    double originLng = 23.322,
    double destLat = 42.710,
    double destLng = 23.340,
  }) =>
      BikeRoute(
        id: id,
        origin: Location(lat: originLat, lng: originLng),
        destination: Location(lat: destLat, lng: destLng),
        waypoints: [
          [42.698, 23.322],
          [42.700, 23.330],
          [42.710, 23.340],
        ],
        distanceMetres: 1500,
        durationSeconds: 360,
        createdAt: DateTime(2025, 1, 1),
      );

  test('saveRoute then getRoute returns the saved route', () async {
    final route = _buildRoute();
    await datasource.saveRoute(route);

    final result = await datasource.getRoute(
      route.origin,
      route.destination,
    );

    expect(result, isNotNull);
    expect(result!.id, equals('route-1'));
    expect(result.distanceMetres, equals(1500));
    expect(result.durationSeconds, equals(360));
    expect(result.waypoints.length, equals(3));
  });

  test('getRoute returns null when cache is empty', () async {
    final result = await datasource.getRoute(
      const Location(lat: 42.698, lng: 23.322),
      const Location(lat: 42.710, lng: 23.340),
    );
    expect(result, isNull);
  });

  test('getRoute respects tolerance — miss outside tolerance', () async {
    final route = _buildRoute();
    await datasource.saveRoute(route);

    final result = await datasource.getRoute(
      const Location(lat: 42.800, lng: 23.322),
      const Location(lat: 42.710, lng: 23.340),
      toleranceDeg: 0.0001,
    );
    expect(result, isNull);
  });

  test('clearRoutes removes all entries', () async {
    await datasource.saveRoute(_buildRoute(id: 'r1'));
    await datasource.saveRoute(
      _buildRoute(id: 'r2', originLat: 42.700, destLat: 42.720),
    );

    await datasource.clearRoutes();

    final result = await datasource.getRoute(
      const Location(lat: 42.698, lng: 23.322),
      const Location(lat: 42.710, lng: 23.340),
    );
    expect(result, isNull);
  });

  test('saveRoute with same id replaces previous entry', () async {
    await datasource.saveRoute(_buildRoute(id: 'route-x'));
    final updated = BikeRoute(
      id: 'route-x',
      origin: const Location(lat: 42.698, lng: 23.322),
      destination: const Location(lat: 42.710, lng: 23.340),
      waypoints: [
        [42.698, 23.322],
        [42.710, 23.340],
      ],
      distanceMetres: 2000,
      durationSeconds: 500,
      createdAt: DateTime(2025, 6, 1),
    );
    await datasource.saveRoute(updated);

    final result = await datasource.getRoute(
      const Location(lat: 42.698, lng: 23.322),
      const Location(lat: 42.710, lng: 23.340),
    );
    expect(result, isNotNull);
    expect(result!.distanceMetres, equals(2000));
  });
}
