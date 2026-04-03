class Location {
  final double lat;
  final double lng;
  final String? address;

  const Location({required this.lat, required this.lng, this.address});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Location &&
          runtimeType == other.runtimeType &&
          lat == other.lat &&
          lng == other.lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}
