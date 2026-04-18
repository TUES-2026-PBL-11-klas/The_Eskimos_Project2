import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'config.dart';

class ApiClient {
  ApiClient()
      : dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.backendBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    if (kDebugMode) {
      debugPrint('[ApiClient] baseUrl = ${AppConfig.backendBaseUrl}');
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: false,
          responseHeader: true,
          responseBody: false,
          error: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onResponse: (res, handler) {
            final data = res.data;
            final size = data is String
                ? data.length
                : data is List
                    ? data.length
                    : data is Map
                        ? data.length
                        : -1;
            debugPrint(
              '[ApiClient] ${res.requestOptions.method} ${res.requestOptions.path} '
              '-> ${res.statusCode} (dataType=${data.runtimeType}, size=$size)',
            );
            handler.next(res);
          },
        ),
      );
    }
  }

  final Dio dio;
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int? statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
