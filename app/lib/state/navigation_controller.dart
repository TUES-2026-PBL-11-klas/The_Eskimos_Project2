import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../data/models/route_response.dart';
import '../../../commits/services/polyline6_decoder.dart';
import '../../../commits/services/route_progress_tracker.dart';

class NavigationState {
  const NavigationState({
    required this.route,
    required this.shape,
    required this.progress,
  });

  final RouteResponseDto route;
  final List<LatLng> shape;
  final RouteProgress? progress;

  NavigationState copyWith({RouteProgress? progress}) => NavigationState(
        route: route,
        shape: shape,
        progress: progress ?? this.progress,
      );
}

class NavigationController extends Notifier<NavigationState?> {
  RouteProgressTracker? _tracker;

  @override
  NavigationState? build() => null;

  void start(RouteResponseDto route) {
    final shape = decodePolyline6(route.polyline);
    _tracker = RouteProgressTracker(shape: shape, maneuvers: route.maneuvers);
    state = NavigationState(route: route, shape: shape, progress: null);
  }

  void updatePosition(LatLng pos) {
    final s = state;
    final t = _tracker;
    if (s == null || t == null) return;
    state = s.copyWith(progress: t.update(pos));
  }

  void stop() {
    _tracker = null;
    state = null;
  }
}

final navigationControllerProvider =
    NotifierProvider<NavigationController, NavigationState?>(
  NavigationController.new,
);
