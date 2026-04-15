import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/bike_profile.dart';
import '../data/models/lat_lng_point.dart';
import '../data/models/route_response.dart';
import 'providers.dart';

class RouteController extends Notifier<AsyncValue<RouteResponseDto?>> {
  @override
  AsyncValue<RouteResponseDto?> build() => const AsyncValue.data(null);

  Future<void> fetch({
    required LatLngPoint start,
    required LatLngPoint end,
    required BikeProfileId profile,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = await ref.read(routingRepositoryProvider.future);
      final route = await repo.fetch(start: start, end: end, profile: profile);
      state = AsyncValue.data(route);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() => state = const AsyncValue.data(null);
}

final routeControllerProvider =
    NotifierProvider<RouteController, AsyncValue<RouteResponseDto?>>(
  RouteController.new,
);
