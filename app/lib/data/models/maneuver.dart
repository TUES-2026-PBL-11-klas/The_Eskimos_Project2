import 'dart:developer' as developer;

class Maneuver {
  const Maneuver({
    required this.instruction,
    required this.streetNames,
    required this.lengthKm,
    required this.timeSeconds,
    required this.type,
    required this.beginShapeIndex,
    required this.endShapeIndex,
  });

  final String instruction;
  final List<String> streetNames;
  final double lengthKm;
  final double timeSeconds;
  final int type;
  final int beginShapeIndex;
  final int endShapeIndex;

  factory Maneuver.fromJson(Map<String, dynamic> j) {
    const required = [
      'instruction',
      'length_km',
      'time_seconds',
      'type',
      'begin_shape_index',
      'end_shape_index',
    ];
    for (final key in required) {
      if (j[key] == null) {
        developer.log(
          'Maneuver.fromJson: missing field "$key"; defaulting',
          name: 'maneuver',
        );
      }
    }
    return Maneuver(
      instruction: j['instruction'] as String? ?? '',
      streetNames: ((j['street_names'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      lengthKm: (j['length_km'] as num?)?.toDouble() ?? 0.0,
      timeSeconds: (j['time_seconds'] as num?)?.toDouble() ?? 0.0,
      type: (j['type'] as num?)?.toInt() ?? 0,
      beginShapeIndex: (j['begin_shape_index'] as num?)?.toInt() ?? 0,
      endShapeIndex: (j['end_shape_index'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'instruction': instruction,
        'street_names': streetNames,
        'length_km': lengthKm,
        'time_seconds': timeSeconds,
        'type': type,
        'begin_shape_index': beginShapeIndex,
        'end_shape_index': endShapeIndex,
      };
}
