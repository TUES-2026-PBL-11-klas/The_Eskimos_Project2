import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../models/bike_profile.dart';
import '../models/geocode_result.dart';
import '../models/route_request.dart';
import '../models/route_response.dart';

class BackendApi {
  BackendApi(this._client);

  final ApiClient _client;

  Future<RouteResponseDto> getRoute(RouteRequestDto req) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/route',
        data: req.toJson(),
      );
      return RouteResponseDto.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException(e.response?.statusCode, _extractMessage(e));
    }
  }

  Future<List<BikeProfile>> listProfiles() async {
    try {
      final res = await _client.dio.get<List<dynamic>>('/api/v1/profiles');
      return res.data!
          .map((e) => BikeProfile.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw ApiException(e.response?.statusCode, _extractMessage(e));
    }
  }

  Future<String> getBikeLanesGeoJson() async {
    try {
      final res = await _client.dio.get<dynamic>(
        '/api/v1/bike-lanes',
        options: Options(responseType: ResponseType.plain),
      );
      return res.data as String;
    } on DioException catch (e) {
      throw ApiException(e.response?.statusCode, _extractMessage(e));
    }
  }

  Future<List<GeocodeResult>> geocode(String query, {int limit = 10}) async {
    try {
      final res = await _client.dio.get<List<dynamic>>(
        '/api/v1/geocode',
        queryParameters: {'q': query, 'limit': limit},
      );
      return res.data!
          .map((e) =>
              GeocodeResult.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw ApiException(e.response?.statusCode, _extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    return e.message ?? 'Network error';
  }
}
