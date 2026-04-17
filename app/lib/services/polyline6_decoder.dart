import 'package:maplibre_gl/maplibre_gl.dart';

/// Decodes Valhalla's polyline6 (1e-6 precision) encoding into LatLng points.
List<LatLng> decodePolyline6(String encoded, {int precision = 6}) {
  final factor = 1 / _pow10(precision);
  final List<LatLng> points = [];
  int index = 0;
  int lat = 0;
  int lon = 0;

  while (index < encoded.length) {
    int result = 1;
    int shift = 0;
    int b;
    do {
      b = encoded.codeUnitAt(index++) - 63 - 1;
      result += b << shift;
      shift += 5;
    } while (b >= 0x1f);
    final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dLat;

    result = 1;
    shift = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63 - 1;
      result += b << shift;
      shift += 5;
    } while (b >= 0x1f);
    final dLon = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lon += dLon;

    points.add(LatLng(lat * factor, lon * factor));
  }

  return points;
}

int _pow10(int n) {
  int v = 1;
  for (int i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}
