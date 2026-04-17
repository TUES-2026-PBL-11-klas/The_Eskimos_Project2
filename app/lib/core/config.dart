import 'package:maplibre_gl/maplibre_gl.dart';

class AppConfig {
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:8001',
  );

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
