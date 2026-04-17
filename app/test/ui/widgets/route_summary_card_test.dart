import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/models/bike_profile.dart';
import 'package:sofia_bike_nav/data/models/route_response.dart';
import 'package:sofia_bike_nav/ui/widgets/route_summary_card.dart';

void main() {
  const profile = BikeProfile(
    name: 'city_bike',
    displayName: 'City Bike',
    description: 'Urban',
    bicycleType: 'hybrid',
    useRoads: 0.5,
    useHills: 0.5,
    cyclingSpeed: 15,
  );

  const route = RouteResponseDto(
    distanceKm: 2.347,
    durationMinutes: 11.6,
    polyline: '',
    legs: [],
    maneuvers: [],
    warnings: [],
  );

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders profile name and formatted metrics', (tester) async {
    await tester.pumpWidget(wrap(RouteSummaryCard(
      route: route,
      profile: profile,
      onStart: () {},
    )));
    expect(find.text('City Bike'), findsOneWidget);
    expect(find.text('2.3 km'), findsOneWidget);
    expect(find.text('12 min'), findsOneWidget);
    expect(find.text('Start navigation'), findsOneWidget);
  });

  testWidgets('tapping Start navigation invokes onStart', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(RouteSummaryCard(
      route: route,
      profile: profile,
      onStart: () => tapped = true,
    )));
    await tester.tap(find.text('Start navigation'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
