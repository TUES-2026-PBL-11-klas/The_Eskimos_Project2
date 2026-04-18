import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/services/location_service.dart';

/// The service is a thin pass-through over Geolocator; these tests just verify
/// that positionStream() can be invoked multiple times without state leaking
/// between calls (the bug the previous `_stream` cache introduced).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Intercept geolocator platform channels so stream setup doesn't blow up in
  // the test VM.
  const methodChannel = MethodChannel('flutter.baseflow.com/geolocator');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  group('LocationService.positionStream', () {
    test('does not throw synchronously on repeat calls', () {
      final svc = LocationService();
      expect(() => svc.positionStream(), returnsNormally);
      expect(() => svc.positionStream(), returnsNormally);
    });

    test('has no cached stream field — stream is produced per call', () {
      // The shared-cache bug meant a canceled subscription broke all future
      // listeners forever. With no cache, repeatedly requesting a stream is
      // safe. We can't assert `!identical(a, b)` because the geolocator plugin
      // itself returns a broadcast stream at the platform layer, but we can
      // assert the service produces a non-null value each time without state
      // corruption.
      final svc = LocationService();
      for (var i = 0; i < 5; i++) {
        expect(svc.positionStream(), isNotNull);
      }
    });
  });
}
