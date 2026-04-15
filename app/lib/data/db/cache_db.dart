import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class CacheDb {
  CacheDb._(this.database);

  final Database database;

  static CacheDb? _instance;

  static Future<CacheDb> instance() async {
    if (_instance != null) return _instance!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'sofia_bike_cache.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE cached_routes (
            id            TEXT PRIMARY KEY,
            geometry_json TEXT NOT NULL,
            steps_json    TEXT NOT NULL,
            distance_m    REAL NOT NULL,
            duration_s    REAL NOT NULL,
            profile       TEXT NOT NULL,
            cached_at     INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE bike_ways_cache (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            geojson      TEXT NOT NULL,
            fetched_at   INTEGER NOT NULL,
            version_hash TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE schema_migrations (
            version    INTEGER PRIMARY KEY,
            applied_at INTEGER NOT NULL
          )
        ''');
        await db.insert('schema_migrations', {
          'version': 1,
          'applied_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      },
    );
    _instance = CacheDb._(db);
    return _instance!;
  }
}
