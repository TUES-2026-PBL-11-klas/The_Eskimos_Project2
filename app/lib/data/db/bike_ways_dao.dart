import 'package:sqflite/sqflite.dart';

import 'cache_db.dart';

class BikeWaysRecord {
  const BikeWaysRecord({
    required this.geojson,
    required this.fetchedAt,
    required this.versionHash,
  });

  final String geojson;
  final int fetchedAt;
  final String versionHash;
}

class BikeWaysDao {
  BikeWaysDao(this._db);

  final CacheDb _db;

  Future<BikeWaysRecord?> getLatest() async {
    final rows = await _db.database.query(
      'bike_ways_cache',
      orderBy: 'fetched_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return BikeWaysRecord(
      geojson: row['geojson'] as String,
      fetchedAt: row['fetched_at'] as int,
      versionHash: row['version_hash'] as String,
    );
  }

  Future<void> put(String geojson, String versionHash) async {
    await _db.database.transaction((txn) async {
      await txn.delete('bike_ways_cache');
      await txn.insert(
        'bike_ways_cache',
        {
          'geojson': geojson,
          'fetched_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          'version_hash': versionHash,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
