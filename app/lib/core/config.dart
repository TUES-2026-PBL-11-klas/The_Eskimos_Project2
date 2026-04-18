import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class AppConfig {
  // For real devices or release builds, pass
  // --dart-define=BACKEND_BASE_URL=https://<your-host>.
  static const String _envBaseUrl = String.fromEnvironment('BACKEND_BASE_URL');

  static String get backendBaseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    // Release builds MUST set BACKEND_BASE_URL (HTTPS) via --dart-define.
    // Falling back to cleartext loopback is only valid in debug/profile.
    if (kReleaseMode) {
      throw StateError(
        'BACKEND_BASE_URL must be provided via --dart-define for release builds',
      );
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:8001';
    return 'http://localhost:8001';
  }

  static const LatLng sofiaCenter = LatLng(42.6977, 23.3219);
  static const double sofiaInitialZoom = 12.0;

  static final LatLngBounds sofiaBounds = LatLngBounds(
    southwest: const LatLng(42.6, 23.15),
    northeast: const LatLng(42.8, 23.55),
  );

  static const String bikeLaneLayerColor = '#2E7D32';
  static const double bikeLaneLayerWidth = 3.0;

  static const int routeCacheTtlSeconds = 24 * 60 * 60;
}
