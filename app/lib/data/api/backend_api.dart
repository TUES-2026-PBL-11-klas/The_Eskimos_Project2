import 'dart:convert';

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
    return _run(() async {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/api/v1/route',
        data: req.toJson(),
      );
      final body = res.data;
      if (body == null) {
        throw ApiException(res.statusCode, 'Empty response from server');
      }
      return RouteResponseDto.fromJson(body);
    });
  }

  Future<List<BikeProfile>> listProfiles() async {
    return _run(() async {
      final res = await _client.dio.get<List<dynamic>>('/api/v1/profiles');
      final body = res.data;
      if (body == null) {
        throw ApiException(res.statusCode, 'Empty response from server');
      }
      return body
          .map((e) => BikeProfile.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  Future<String> getBikeLanesGeoJson() async {
    return _run(() async {
      final res = await _client.dio.get<dynamic>(
        '/api/v1/bike-lanes',
        options: Options(responseType: ResponseType.plain),
      );
      final body = res.data;
      if (body is! String) {
        throw ApiException(res.statusCode, 'Unexpected bike-lanes response');
      }
      return body;
    });
  }

  Future<List<GeocodeResult>> geocode(String query, {int limit = 10}) async {
    return _run(() async {
      final res = await _client.dio.get<List<dynamic>>(
        '/api/v1/geocode',
        queryParameters: {'q': query, 'limit': limit},
      );
      final body = res.data;
      if (body == null) {
        throw ApiException(res.statusCode, 'Empty response from server');
      }
      return body
          .map((e) =>
              GeocodeResult.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });
  }

  /// Wraps a Dio call with typed exception handling and a single retry
  /// on connection timeouts (transient network hiccups, not server errors).
  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        try {
          return await call();
        } on DioException catch (e2) {
          throw ApiException(e2.response?.statusCode, _extractMessage(e2));
        }
      }
      throw ApiException(e.response?.statusCode, _extractMessage(e));
    }
  }

  String _extractMessage(DioException e) {
    dynamic data = e.response?.data;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        // Body isn't JSON — fall through to e.message.
      }
    }
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List) {
        final msgs = detail
            .whereType<Map>()
            .map((m) => m['msg']?.toString())
            .whereType<String>()
            .toList();
        if (msgs.isNotEmpty) return msgs.join('; ');
      }
      if (detail != null) return detail.toString();
    }
    return e.message ?? 'Network error';
  }
}
