import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/config.dart';
import '../models/bike_profile.dart';
import '../models/lat_lng_point.dart';
import '../models/maneuver.dart';
import '../models/route_response.dart';
import 'cache_db.dart';

class RoutesDao {
  RoutesDao(this._db);

  final CacheDb _db;

  static String idFor(
    LatLngPoint start,
    LatLngPoint end,
    BikeProfileId profile,
  ) {
    String r(double v) => v.toStringAsFixed(5);
    return '${r(start.lat)},${r(start.lon)}->${r(end.lat)},${r(end.lon)}:${profile.value}';
  }

  Future<RouteResponseDto?> get(String id) async {
    // Atomic read-then-expire so a concurrent writer can't insert a fresh row
    // between the SELECT and the DELETE.
    return _db.database.transaction((txn) async {
      final rows = await txn.query(
        'cached_routes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final row = rows.first;
      final cachedAt = row['cached_at'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (now - cachedAt > AppConfig.routeCacheTtlSeconds) {
        await txn.delete(
          'cached_routes',
          where: 'id = ? AND cached_at = ?',
          whereArgs: [id, cachedAt],
        );
        return null;
      }
      final geometry =
          json.decode(row['geometry_json'] as String) as Map<String, dynamic>;
      final steps = (json.decode(row['steps_json'] as String) as List)
          .map((e) => Maneuver.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return RouteResponseDto(
        distanceKm: (row['distance_m'] as num).toDouble() / 1000.0,
        durationMinutes: (row['duration_s'] as num).toDouble() / 60.0,
        polyline: geometry['polyline'] as String? ?? '',
        maneuvers: steps,
      );
    });
  }

  Future<void> put(
    String id,
    RouteResponseDto route,
    BikeProfileId profile,
  ) async {
    await _db.database.transaction((txn) async {
      await txn.insert(
        'cached_routes',
        {
          'id': id,
          'geometry_json': json.encode({'polyline': route.polyline}),
          'steps_json':
              json.encode(route.maneuvers.map((m) => m.toJson()).toList()),
          'distance_m': route.distanceKm * 1000.0,
          'duration_s': route.durationMinutes * 60.0,
          'profile': profile.value,
          'cached_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
