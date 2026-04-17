class LatLngPoint {
  const LatLngPoint(this.lat, this.lon);

  final double lat;
  final double lon;

  Map<String, dynamic> toJson() => {'lat': lat, 'lon': lon};

  factory LatLngPoint.fromJson(Map<String, dynamic> j) =>
      LatLngPoint((j['lat'] as num).toDouble(), (j['lon'] as num).toDouble());
}
