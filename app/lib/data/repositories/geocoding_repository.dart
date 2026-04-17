import '../api/backend_api.dart';
import '../models/geocode_result.dart';

class GeocodingRepository {
  GeocodingRepository(this._api);

  final BackendApi _api;

  Future<List<GeocodeResult>> search(String query, {int limit = 10}) {
    if (query.trim().length < 2) return Future.value(const []);
    return _api.geocode(query.trim(), limit: limit);
  }
}
