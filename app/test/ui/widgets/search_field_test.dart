import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/data/api/backend_api.dart';
import 'package:sofia_bike_nav/data/models/geocode_result.dart';
import 'package:sofia_bike_nav/data/repositories/geocoding_repository.dart';
import 'package:sofia_bike_nav/ui/widgets/search_field.dart';

class _FakeApi implements BackendApi {
  _FakeApi(this.results);
  final List<GeocodeResult> results;

  @override
  Future<List<GeocodeResult>> geocode(String q, {int limit = 10}) async {
    return results;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders the label', (tester) async {
    final repo = GeocodingRepository(_FakeApi(const []));
    await tester.pumpWidget(wrap(SearchField(
      repo: repo,
      onPicked: (_) {},
      label: 'Destination:',
    )));
    expect(find.text('Destination:'), findsOneWidget);
  });

  testWidgets('shows results after typing and picks one', (tester) async {
    final repo = GeocodingRepository(_FakeApi(const [
      GeocodeResult(label: 'Sofia Center', lat: 42.0, lon: 23.0),
      GeocodeResult(label: 'Sofia South', lat: 42.1, lon: 23.1),
    ]));

    GeocodeResult? picked;
    await tester.pumpWidget(wrap(SearchField(
      repo: repo,
      onPicked: (r) => picked = r,
    )));

    await tester.enterText(find.byType(TextField), 'sofia');
    // Allow debounce timer (300ms) to elapse, then the async future.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Sofia Center'), findsOneWidget);
    expect(find.text('Sofia South'), findsOneWidget);

    await tester.tap(find.text('Sofia Center'));
    await tester.pump();
    expect(picked?.label, 'Sofia Center');
  });

  testWidgets('hides results when query is shorter than 2 chars',
      (tester) async {
    final repo = GeocodingRepository(_FakeApi(const [
      GeocodeResult(label: 'Sofia', lat: 42.0, lon: 23.0),
    ]));
    await tester.pumpWidget(wrap(SearchField(
      repo: repo,
      onPicked: (_) {},
    )));
    await tester.enterText(find.byType(TextField), 's');
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Sofia'), findsNothing);
  });
}
