import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sofia_bike_nav/data/datasources/local/database_helper.dart';
import 'package:sofia_bike_nav/data/datasources/local/bike_way_local_datasource.dart';
import 'package:sofia_bike_nav/domain/entities/bike_way.dart';

void main() {
  late DatabaseHelper dbHelper;
  late BikeWayLocalDatasource datasource;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.forPath(':memory:');
    datasource = BikeWayLocalDatasource(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  BikeWay _buildWay({
    String id = 'way-1',
    String name = 'Велоалея бул. Витоша',
    String type = 'На пътното платно обособена',
  }) =>
      BikeWay(
        id: id,
        name: name,
        type: type,
        coordinates: [
          [42.698, 23.322],
          [42.700, 23.325],
        ],
        propertiesJson: '{"source":"sofiaplan"}',
      );

  test('getBikeWays returns empty list when cache is empty', () async {
    final result = await datasource.getBikeWays();
    expect(result, isEmpty);
  });

  test('saveBikeWays then getBikeWays returns saved ways', () async {
    final ways = [_buildWay(), _buildWay(id: 'way-2', name: 'Велоалея ул. Граф')];
    await datasource.saveBikeWays(ways);

    final result = await datasource.getBikeWays();
    expect(result.length, equals(2));

    final ids = result.map((w) => w.id).toSet();
    expect(ids, containsAll(['way-1', 'way-2']));
  });

  test('saveBikeWays replaces existing entries', () async {
    await datasource.saveBikeWays([_buildWay(id: 'old-1'), _buildWay(id: 'old-2')]);
    await datasource.saveBikeWays([_buildWay(id: 'new-1')]);

    final result = await datasource.getBikeWays();
    expect(result.length, equals(1));
    expect(result.first.id, equals('new-1'));
  });

  test('clearBikeWays removes all entries', () async {
    await datasource.saveBikeWays([_buildWay(), _buildWay(id: 'way-2')]);
    await datasource.clearBikeWays();

    final result = await datasource.getBikeWays();
    expect(result, isEmpty);
  });

  test('coordinates round-trip is preserved', () async {
    final way = _buildWay();
    await datasource.saveBikeWays([way]);

    final result = await datasource.getBikeWays();
    expect(result.first.coordinates, equals(way.coordinates));
  });

  test('optional fields are preserved as null', () async {
    const minimalWay = BikeWay(
      id: 'minimal',
      coordinates: [
        [42.7, 23.3],
      ],
    );
    await datasource.saveBikeWays([minimalWay]);

    final result = await datasource.getBikeWays();
    expect(result.first.name, isNull);
    expect(result.first.type, isNull);
    expect(result.first.propertiesJson, isNull);
  });
}
