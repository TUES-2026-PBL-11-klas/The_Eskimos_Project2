import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../api/backend_api.dart';
import '../db/bike_ways_dao.dart';

class BikeLanesRepository {
  BikeLanesRepository(this._api, this._dao);

  final BackendApi _api;
  final BikeWaysDao _dao;

  /// Observable error state for the most recent background refresh.
  /// null = last refresh succeeded (or none attempted).
  Object? lastRefreshError;
  DateTime? lastRefreshAt;

  Future<String> load({bool forceRefresh = false}) async {
    final cached = await _dao.getLatest();
    if (cached != null && !forceRefresh) {
      _refreshInBackground(cached.versionHash);
      return cached.geojson;
    }
    final fresh = await _api.getBikeLanesGeoJson();
    final hash = md5.convert(utf8.encode(fresh)).toString();
    await _dao.put(fresh, hash);
    lastRefreshError = null;
    lastRefreshAt = DateTime.now();
    return fresh;
  }

  Future<void> _refreshInBackground(String knownHash) async {
    try {
      final fresh = await _api.getBikeLanesGeoJson();
      final hash = md5.convert(utf8.encode(fresh)).toString();
      if (hash != knownHash) {
        await _dao.put(fresh, hash);
      }
      lastRefreshError = null;
    } on SocketException {
      // Offline is expected; keep cached copy without flagging an error.
      lastRefreshError = null;
    } catch (e, st) {
      lastRefreshError = e;
      developer.log(
        'bike-lanes background refresh failed',
        name: 'bike_lanes_repository',
        error: e,
        stackTrace: st,
      );
    } finally {
      lastRefreshAt = DateTime.now();
    }
  }
}
