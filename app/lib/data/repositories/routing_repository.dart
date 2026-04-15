import '../api/backend_api.dart';
import '../db/routes_dao.dart';
import '../models/bike_profile.dart';
import '../models/lat_lng_point.dart';
import '../models/route_request.dart';
import '../models/route_response.dart';

class RoutingRepository {
  RoutingRepository(this._api, this._dao);

  final BackendApi _api;
  final RoutesDao _dao;

  Future<RouteResponseDto> fetch({
    required LatLngPoint start,
    required LatLngPoint end,
    required BikeProfileId profile,
  }) async {
    final id = RoutesDao.idFor(start, end, profile);
    final cached = await _dao.get(id);
    if (cached != null) return cached;

    final fresh = await _api.getRoute(
      RouteRequestDto(start: start, end: end, profile: profile),
    );
    await _dao.put(id, fresh, profile);
    return fresh;
  }
}
