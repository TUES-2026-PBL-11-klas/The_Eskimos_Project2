import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../api/backend_api.dart';
import '../db/bike_ways_dao.dart';

class BikeLanesRepository {
  BikeLanesRepository(this._api, this._dao);

  final BackendApi _api;
  final BikeWaysDao _dao;

  Future<String> load({bool forceRefresh = false}) async {
    final cached = await _dao.getLatest();
    if (cached != null && !forceRefresh) {
      _refreshInBackground(cached.versionHash);
      return cached.geojson;
    }
    final fresh = await _api.getBikeLanesGeoJson();
    final hash = md5.convert(utf8.encode(fresh)).toString();
    await _dao.put(fresh, hash);
    return fresh;
  }

  Future<void> _refreshInBackground(String knownHash) async {
    try {
      final fresh = await _api.getBikeLanesGeoJson();
      final hash = md5.convert(utf8.encode(fresh)).toString();
      if (hash != knownHash) {
        await _dao.put(fresh, hash);
      }
    } catch (_) {
      // offline — keep cached copy
    }
  }
}
