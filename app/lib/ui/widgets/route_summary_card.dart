import 'package:flutter/material.dart';

import '../../data/models/bike_profile.dart';
import '../../data/models/route_response.dart';

class RouteSummaryCard extends StatelessWidget {
  const RouteSummaryCard({
    super.key,
    required this.route,
    required this.profile,
    required this.onStart,
  });

  final RouteResponseDto route;
  final BikeProfile profile;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_bike),
                const SizedBox(width: 8),
                Text(profile.displayName, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Metric(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: '${route.distanceKm.toStringAsFixed(1)} km',
                ),
                const SizedBox(width: 24),
                _Metric(
                  icon: Icons.schedule,
                  label: 'Time',
                  value: '${route.durationMinutes.toStringAsFixed(0)} min',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.navigation),
                label: const Text('Start navigation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 18), const SizedBox(width: 4), Text(label)]),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
