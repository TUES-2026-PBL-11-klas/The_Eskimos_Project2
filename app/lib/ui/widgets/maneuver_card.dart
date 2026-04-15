import 'package:flutter/material.dart';

import '../../data/models/maneuver.dart';

IconData maneuverIcon(int type) {
  switch (type) {
    case 1:
      return Icons.trip_origin;
    case 4:
    case 5:
    case 6:
      return Icons.flag;
    case 8:
      return Icons.straight;
    case 9:
    case 10:
      return Icons.turn_slight_right;
    case 11:
      return Icons.turn_right;
    case 12:
      return Icons.turn_sharp_right;
    case 13:
    case 14:
      return Icons.turn_slight_left;
    case 15:
      return Icons.turn_left;
    case 16:
      return Icons.turn_sharp_left;
    case 17:
    case 18:
      return Icons.u_turn_left;
    default:
      return Icons.arrow_upward;
  }
}

class ManeuverCard extends StatelessWidget {
  const ManeuverCard({
    super.key,
    required this.maneuver,
    required this.distanceToNextM,
    required this.remainingMinutes,
    required this.onStop,
  });

  final Maneuver maneuver;
  final double distanceToNextM;
  final double remainingMinutes;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(maneuverIcon(maneuver.type), size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maneuver.instruction,
                        style: theme.textTheme.titleMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'in ${_formatDistance(distanceToNextM)}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ETA ${remainingMinutes.toStringAsFixed(0)} min',
                  style: theme.textTheme.bodyMedium,
                ),
                TextButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.close),
                  label: const Text('Stop'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDistance(double m) {
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }
}
