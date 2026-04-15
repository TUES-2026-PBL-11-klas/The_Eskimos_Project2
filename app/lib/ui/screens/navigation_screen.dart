import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/models/route_response.dart';
import '../../services/tile_server.dart';
import '../../state/navigation_controller.dart';
import '../../state/providers.dart';
import '../widgets/maneuver_card.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key, required this.route});

  final RouteResponseDto route;

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  MapLibreMapController? _map;
  bool _routeDrawn = false;
  String? _styleStringPath;
  ProviderSubscription<AsyncValue<dynamic>>? _posSub;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    TileServer.instance.prepareStyle().then((path) {
      if (mounted) setState(() => _styleStringPath = path);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationControllerProvider.notifier).start(widget.route);
      _posSub = ref.listenManual(currentPositionProvider, (prev, next) {
        next.whenData((pos) {
          final ll = LatLng(pos.latitude, pos.longitude);
          ref
              .read(navigationControllerProvider.notifier)
              .updatePosition(ll);
          _map?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: ll,
                zoom: 17,
                tilt: 50,
                bearing: pos.heading,
              ),
            ),
          );
        });
      });
    });
  }

  @override
  void dispose() {
    _posSub?.close();
    WakelockPlus.disable();
    ref.read(navigationControllerProvider.notifier).stop();
    super.dispose();
  }

  Future<void> _onStyleLoaded() async {
    if (_routeDrawn || _map == null) return;
    final shape = ref.read(navigationControllerProvider)?.shape;
    if (shape == null) return;
    final coords = shape.map((p) => [p.longitude, p.latitude]).toList();
    final geojson = {
      'type': 'Feature',
      'geometry': {'type': 'LineString', 'coordinates': coords},
      'properties': <String, dynamic>{},
    };
    await _map!.addSource(
      'route-src',
      GeojsonSourceProperties(data: geojson),
    );
    await _map!.addLineLayer(
      'route-src',
      'route-layer',
      const LineLayerProperties(
        lineColor: '#1565C0',
        lineWidth: 6,
        lineOpacity: 0.9,
      ),
    );
    _routeDrawn = true;
  }

  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationControllerProvider);
    final route = widget.route;
    final progress = nav?.progress;
    final maneuverIdx = progress?.currentManeuver ?? 0;
    final maneuver =
        route.maneuvers.isEmpty ? null : route.maneuvers[maneuverIdx];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _styleStringPath == null
                ? const Center(child: CircularProgressIndicator())
                : MapLibreMap(
                    styleString: _styleStringPath!,
                    initialCameraPosition: CameraPosition(
                      target:
                          nav?.shape.first ?? const LatLng(42.6977, 23.3219),
                      zoom: 17,
                      tilt: 50,
                    ),
                    onMapCreated: (c) => _map = c,
                    onStyleLoadedCallback: _onStyleLoaded,
                    myLocationEnabled: true,
                  ),
          ),
          Expanded(
            flex: 2,
            child: maneuver == null
                ? const Center(child: CircularProgressIndicator())
                : ManeuverCard(
                    maneuver: maneuver,
                    distanceToNextM:
                        progress?.distanceToNextManeuverM ?? 0,
                    remainingMinutes:
                        (progress?.remainingDurationSeconds ??
                                route.durationMinutes * 60) /
                            60.0,
                    onStop: () => Navigator.pop(context),
                  ),
          ),
        ],
      ),
    );
  }
}
