class GeocodeResult {
  const GeocodeResult({
    required this.label,
    required this.lat,
    required this.lon,
  });

  final String label;
  final double lat;
  final double lon;

  factory GeocodeResult.fromJson(Map<String, dynamic> j) => GeocodeResult(
        label: j['label'] as String,
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
      );
}
