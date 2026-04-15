enum BikeProfileId {
  cityBike('city_bike'),
  mountainBike('mountain_bike'),
  electricBike('electric_bike');

  const BikeProfileId(this.value);
  final String value;

  static BikeProfileId fromValue(String v) =>
      BikeProfileId.values.firstWhere((e) => e.value == v,
          orElse: () => BikeProfileId.cityBike);
}

class BikeProfile {
  const BikeProfile({
    required this.name,
    required this.displayName,
    required this.description,
    required this.bicycleType,
    required this.useRoads,
    required this.useHills,
    required this.cyclingSpeed,
  });

  final String name;
  final String displayName;
  final String description;
  final String bicycleType;
  final double useRoads;
  final double useHills;
  final double cyclingSpeed;

  BikeProfileId get id => BikeProfileId.fromValue(name);

  factory BikeProfile.fromJson(Map<String, dynamic> j) => BikeProfile(
        name: j['name'] as String,
        displayName: j['display_name'] as String,
        description: j['description'] as String,
        bicycleType: j['bicycle_type'] as String,
        useRoads: (j['use_roads'] as num).toDouble(),
        useHills: (j['use_hills'] as num).toDouble(),
        cyclingSpeed: (j['cycling_speed'] as num).toDouble(),
      );
}
