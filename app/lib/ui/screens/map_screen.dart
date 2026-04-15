import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../commits/core/config.dart';
import '../../../../commits/services/tile_server.dart';
import '../../state/providers.dart';
import 'search_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapLibreMapController? _map;
  String? _styleStringPath;
  bool _bikeLanesAdded = false;

  @override
  void initState() {
    super.initState();
    _prepareStyle();
  }

  Future<void> _prepareStyle() async {
    final stylePath = await TileServer.instance.prepareStyle();
    if (mounted) setState(() => _styleStringPath = stylePath);
  }

  Future<void> _onMapCreated(MapLibreMapController c) async {
    _map = c;
  }

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null || _bikeLanesAdded) return;
    try {
      final geojson = await ref.read(bikeLanesGeoJsonProvider.future);
      await map.addSource(
        'bike-lanes-src',
        GeojsonSourceProperties(data: geojson),
      );
      await map.addLineLayer(
        'bike-lanes-src',
        'bike-lanes-layer',
        const LineLayerProperties(
          lineColor: AppConfig.bikeLaneLayerColor,
          lineWidth: AppConfig.bikeLaneLayerWidth,
          lineOpacity: 0.9,
        ),
      );
      _bikeLanesAdded = true;
    } catch (_) {
      // offline or no cache yet — render base map without lanes
    }
  }

  Future<void> _centerOnUser() async {
    final pos = await ref.read(locationServiceProvider).currentPosition();
    if (pos == null || _map == null) return;
    await _map!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);
    if (_styleStringPath == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: _styleStringPath!,
            initialCameraPosition: const CameraPosition(
              target: AppConfig.sofiaCenter,
              zoom: AppConfig.sofiaInitialZoom,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            myLocationEnabled: true,
            myLocationRenderMode: MyLocationRenderMode.compass,
            trackCameraPosition: false,
          ),
          positionAsync.when(
            data: (_) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.black54,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Location permission denied',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'center',
            onPressed: _centerOnUser,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'search',
            onPressed: _openSearch,
            icon: const Icon(Icons.directions),
            label: const Text('Find route'),
          ),
        ],
      ),
    );
  }
}
