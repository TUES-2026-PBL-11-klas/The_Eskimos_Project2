import 'package:flutter/material.dart';

import '../../data/models/bike_profile.dart';

class BikeProfileDropdown extends StatelessWidget {
  const BikeProfileDropdown({
    super.key,
    required this.profiles,
    required this.selected,
    required this.onChanged,
  });

  final List<BikeProfile> profiles;
  final BikeProfile? selected;
  final ValueChanged<BikeProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Bike type',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BikeProfile>(
          value: selected,
          isExpanded: true,
          items: profiles
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.displayName),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
