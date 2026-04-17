import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/models/maneuver.dart';
import 'package:sofia_bike_nav/ui/widgets/maneuver_card.dart';

void main() {
  group('maneuverIcon', () {
    test('maps the known types to the expected icons', () {
      expect(maneuverIcon(1), Icons.trip_origin);
      expect(maneuverIcon(4), Icons.flag);
      expect(maneuverIcon(5), Icons.flag);
      expect(maneuverIcon(6), Icons.flag);
      expect(maneuverIcon(8), Icons.straight);
      expect(maneuverIcon(9), Icons.turn_slight_right);
      expect(maneuverIcon(10), Icons.turn_slight_right);
      expect(maneuverIcon(11), Icons.turn_right);
      expect(maneuverIcon(12), Icons.turn_sharp_right);
      expect(maneuverIcon(13), Icons.turn_slight_left);
      expect(maneuverIcon(14), Icons.turn_slight_left);
      expect(maneuverIcon(15), Icons.turn_left);
      expect(maneuverIcon(16), Icons.turn_sharp_left);
      expect(maneuverIcon(17), Icons.u_turn_left);
      expect(maneuverIcon(18), Icons.u_turn_left);
    });

    test('falls back to arrow_upward for unknown types', () {
      expect(maneuverIcon(0), Icons.arrow_upward);
      expect(maneuverIcon(99), Icons.arrow_upward);
      expect(maneuverIcon(-1), Icons.arrow_upward);
    });
  });

  group('ManeuverCard widget', () {
    const maneuver = Maneuver(
      instruction: 'Turn right onto Vitosha',
      streetNames: ['Vitosha'],
      lengthKm: 0.3,
      timeSeconds: 60,
      type: 11,
      beginShapeIndex: 0,
      endShapeIndex: 3,
    );

    Widget wrap(Widget child) =>
        MaterialApp(home: Scaffold(body: child));

    testWidgets('renders instruction and metric text', (tester) async {
      var stopped = false;
      await tester.pumpWidget(wrap(ManeuverCard(
        maneuver: maneuver,
        distanceToNextM: 250,
        remainingMinutes: 12,
        onStop: () => stopped = true,
      )));
      expect(find.text('Turn right onto Vitosha'), findsOneWidget);
      expect(find.text('in 250 m'), findsOneWidget);
      expect(find.text('ETA 12 min'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      await tester.tap(find.text('Stop'));
      expect(stopped, isTrue);
    });

    testWidgets('formats distance in km when over 1000 m', (tester) async {
      await tester.pumpWidget(wrap(ManeuverCard(
        maneuver: maneuver,
        distanceToNextM: 1500,
        remainingMinutes: 3,
        onStop: () {},
      )));
      expect(find.text('in 1.5 km'), findsOneWidget);
    });

    testWidgets('rounds distance < 1000 m to the nearest meter',
        (tester) async {
      await tester.pumpWidget(wrap(ManeuverCard(
        maneuver: maneuver,
        distanceToNextM: 123.7,
        remainingMinutes: 1,
        onStop: () {},
      )));
      expect(find.text('in 124 m'), findsOneWidget);
    });
  });
}
