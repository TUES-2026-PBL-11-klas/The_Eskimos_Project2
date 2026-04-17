import 'package:flutter_test/flutter_test.dart';
import 'package:sofia_bike_nav/core/config.dart';

void main() {
  group('AppConfig', () {
    test('Sofia center is inside Sofia bounds', () {
      final sw = AppConfig.sofiaBounds.southwest;
      final ne = AppConfig.sofiaBounds.northeast;
      expect(AppConfig.sofiaCenter.latitude,
          inInclusiveRange(sw.latitude, ne.latitude));
      expect(AppConfig.sofiaCenter.longitude,
          inInclusiveRange(sw.longitude, ne.longitude));
    });

    test('initial zoom is a reasonable city-level zoom', () {
      expect(AppConfig.sofiaInitialZoom, inInclusiveRange(8.0, 18.0));
    });

    test('bike lane styling constants are sane', () {
      expect(AppConfig.bikeLaneLayerColor, startsWith('#'));
      expect(AppConfig.bikeLaneLayerWidth, greaterThan(0));
    });

    test('route cache TTL is 24 hours', () {
      expect(AppConfig.routeCacheTtlSeconds, 24 * 60 * 60);
    });

    test('backend base URL is non-empty', () {
      expect(AppConfig.backendBaseUrl, isNotEmpty);
    });
  });
}
