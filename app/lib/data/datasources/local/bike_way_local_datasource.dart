import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:sofia_bike_nav/data/datasources/local/database_helper.dart';
import 'package:sofia_bike_nav/domain/entities/bike_way.dart';

/// Reads and writes [BikeWay] records in the local SQLite database.
class BikeWayLocalDatasource {
  final DatabaseHelper _dbHelper;

  BikeWayLocalDatasource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Returns all bike ways stored in the cache.
  Future<List<BikeWay>> getBikeWays() async {
    final db = await _dbHelper.database;
    final rows = await db.query(kTableBikeWays);
    return rows.map(_fromMap).toList();
  }

  /// Replaces the entire bike-way cache with [bikeWays] inside a transaction.
  Future<void> saveBikeWays(List<BikeWay> bikeWays) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(kTableBikeWays);
      for (final way in bikeWays) {
        await txn.insert(
          kTableBikeWays,
          _toMap(way),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Deletes every row from the bike_ways table.
  Future<void> clearBikeWays() async {
    final db = await _dbHelper.database;
    await db.delete(kTableBikeWays);
  }

  Map<String, Object?> _toMap(BikeWay way) => {
        'id': way.id,
        'name': way.name,
        'type': way.type,
        'coordinates': jsonEncode(way.coordinates),
        'properties_json': way.propertiesJson,
      };

  BikeWay _fromMap(Map<String, Object?> map) {
    final rawCoords =
        jsonDecode(map['coordinates'] as String) as List<dynamic>;
    final coordinates = rawCoords
        .map((e) => (e as List<dynamic>).map((v) => (v as num).toDouble()).toList())
        .toList();

    return BikeWay(
      id: map['id'] as String,
      name: map['name'] as String?,
      type: map['type'] as String?,
      coordinates: coordinates,
      propertiesJson: map['properties_json'] as String?,
    );
  }
}
