import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:sofia_bike_nav/data/datasources/local/database_helper.dart';
import 'package:sofia_bike_nav/domain/entities/bike_route.dart';
import 'package:sofia_bike_nav/domain/entities/location.dart';

/// Reads and writes [BikeRoute] records in the local SQLite database.
class RouteLocalDatasource {
  final DatabaseHelper _dbHelper;

  RouteLocalDatasource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Returns the first cached route whose origin and destination are within
  /// [toleranceDeg] degrees of [origin] and [destination], or `null`.
  Future<BikeRoute?> getRoute(
    Location origin,
    Location destination, {
    double toleranceDeg = 0.0001,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      kTableRoutes,
      where: '''
        ABS(origin_lat - ?) <= ? AND
        ABS(origin_lng - ?) <= ? AND
        ABS(dest_lat   - ?) <= ? AND
        ABS(dest_lng   - ?) <= ?
      ''',
      whereArgs: [
        origin.lat,
        toleranceDeg,
        origin.lng,
        toleranceDeg,
        destination.lat,
        toleranceDeg,
        destination.lng,
        toleranceDeg,
      ],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return _fromMap(rows.first);
  }

  /// Inserts or replaces [route] in the cache.
  Future<void> saveRoute(BikeRoute route) async {
    final db = await _dbHelper.database;
    await db.insert(
      kTableRoutes,
      _toMap(route),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes every row from the routes table.
  Future<void> clearRoutes() async {
    final db = await _dbHelper.database;
    await db.delete(kTableRoutes);
  }

  Map<String, Object?> _toMap(BikeRoute route) => {
        'id': route.id,
        'origin_lat': route.origin.lat,
        'origin_lng': route.origin.lng,
        'dest_lat': route.destination.lat,
        'dest_lng': route.destination.lng,
        'waypoints': jsonEncode(route.waypoints),
        'distance_m': route.distanceMetres,
        'duration_s': route.durationSeconds,
        'created_at': route.createdAt.millisecondsSinceEpoch,
      };

  BikeRoute _fromMap(Map<String, Object?> map) {
    final rawWaypoints =
        jsonDecode(map['waypoints'] as String) as List<dynamic>;
    final waypoints = rawWaypoints
        .map((e) => (e as List<dynamic>).map((v) => (v as num).toDouble()).toList())
        .toList();

    return BikeRoute(
      id: map['id'] as String,
      origin: Location(
        lat: map['origin_lat'] as double,
        lng: map['origin_lng'] as double,
      ),
      destination: Location(
        lat: map['dest_lat'] as double,
        lng: map['dest_lng'] as double,
      ),
      waypoints: waypoints,
      distanceMetres: map['distance_m'] as double,
      durationSeconds: map['duration_s'] as double,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
