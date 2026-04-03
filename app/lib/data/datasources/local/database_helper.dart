import 'package:sqflite/sqflite.dart';

const _kDatabaseName = 'sofia_bike_nav.db';
const _kDatabaseVersion = 1;

const kTableRoutes = 'routes';
const kTableBikeWays = 'bike_ways';

/// Manages the application SQLite database lifecycle.
///
/// Use [DatabaseHelper.instance] for the production singleton.
/// Use [DatabaseHelper.forPath] to create an isolated instance (e.g. tests).
class DatabaseHelper {
  DatabaseHelper._(this._dbPath);

  /// The shared production instance backed by [_kDatabaseName].
  static final DatabaseHelper instance = DatabaseHelper._(_kDatabaseName);

  /// Creates an independent helper pointing at [path].
  ///
  /// Pass `':memory:'` for a throw-away in-memory database.
  factory DatabaseHelper.forPath(String path) => DatabaseHelper._(path);

  final String _dbPath;
  Database? _database;

  Future<Database> get database async {
    _database ??= await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() {
    return openDatabase(
      _dbPath,
      version: _kDatabaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $kTableRoutes (
        id           TEXT    PRIMARY KEY,
        origin_lat   REAL    NOT NULL,
        origin_lng   REAL    NOT NULL,
        dest_lat     REAL    NOT NULL,
        dest_lng     REAL    NOT NULL,
        waypoints    TEXT    NOT NULL,
        distance_m   REAL    NOT NULL,
        duration_s   REAL    NOT NULL,
        created_at   INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $kTableBikeWays (
        id              TEXT PRIMARY KEY,
        name            TEXT,
        type            TEXT,
        coordinates     TEXT NOT NULL,
        properties_json TEXT
      )
    ''');
  }

  /// Closes the underlying database connection. Mainly used in tests.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
