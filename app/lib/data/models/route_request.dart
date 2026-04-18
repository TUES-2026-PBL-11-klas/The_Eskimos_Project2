import 'bike_profile.dart';
import 'lat_lng_point.dart';

class RouteRequestDto {
  const RouteRequestDto({
    required this.start,
    required this.end,
    required this.profile,
    this.avoidDangerous = true,
    this.language = 'bg-BG',
    this.extraAvoidPolygons = const [],
  });

  final LatLngPoint start;
  final LatLngPoint end;
  final BikeProfileId profile;
  final bool avoidDangerous;
  final String language;
  final List<List<LatLngPoint>> extraAvoidPolygons;

  Map<String, dynamic> toJson() => {
        'start': start.toJson(),
        'end': end.toJson(),
        'profile': profile.value,
        'avoid_dangerous': avoidDangerous,
        'include_elevation': false,
        'language': language,
        'extra_avoid_polygons':
            extraAvoidPolygons.map((p) => p.map((c) => c.toJson()).toList()).toList(),
      };
}
