class BikeWay {
  final String id;
  final String? name;

  /// One of: Контрафлоу, На пътното платно, На пътното платно обособена,
  /// На тротоара, На тротоара обособена, На тротоара споделена с пешеходци.
  final String? type;

  /// Ordered list of [lat, lng] coordinate pairs that form the geometry.
  final List<List<double>> coordinates;

  /// Extra GeoJSON properties stored as a raw JSON string.
  final String? propertiesJson;

  const BikeWay({
    required this.id,
    this.name,
    this.type,
    required this.coordinates,
    this.propertiesJson,
  });
}
