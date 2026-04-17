import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/models/bike_profile.dart';
import 'package:sofia_bike_nav/ui/widgets/bike_profile_dropdown.dart';

void main() {
  const profiles = [
    BikeProfile(
      name: 'city_bike',
      displayName: 'City Bike',
      description: 'Urban',
      bicycleType: 'hybrid',
      useRoads: 0.5,
      useHills: 0.5,
      cyclingSpeed: 15,
    ),
    BikeProfile(
      name: 'mountain_bike',
      displayName: 'Mountain Bike',
      description: 'Offroad',
      bicycleType: 'mountain',
      useRoads: 0.3,
      useHills: 0.8,
      cyclingSpeed: 18,
    ),
  ];

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders selected profile label', (tester) async {
    await tester.pumpWidget(wrap(BikeProfileDropdown(
      profiles: profiles,
      selected: profiles[0],
      onChanged: (_) {},
    )));
    expect(find.text('City Bike'), findsOneWidget);
    expect(find.text('Bike type'), findsOneWidget);
  });

  testWidgets('invokes onChanged when a new profile is picked',
      (tester) async {
    BikeProfile? picked;
    await tester.pumpWidget(wrap(BikeProfileDropdown(
      profiles: profiles,
      selected: profiles[0],
      onChanged: (p) => picked = p,
    )));

    await tester.tap(find.byType(DropdownButton<BikeProfile>));
    await tester.pumpAndSettle();
    // Two matches: shown in the closed state AND in the opened menu. Tap the
    // second one (the menu item).
    await tester.tap(find.text('Mountain Bike').last);
    await tester.pumpAndSettle();
    expect(picked?.name, 'mountain_bike');
  });
}
