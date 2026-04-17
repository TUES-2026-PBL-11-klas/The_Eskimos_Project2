import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../core/config.dart';
import '../../data/models/geocode_result.dart';
import '../../services/tile_server.dart';
import '../../state/providers.dart';
import '../widgets/search_field.dart';
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
  bool _permissionResolved = false;
  Circle? _searchMarker;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await ref.read(locationServiceProvider).ensurePermission();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _permissionResolved = true);
    try {
      final stylePath = await TileServer.instance.prepareStyle();
      if (mounted) setState(() => _styleStringPath = stylePath);
    } catch (e) {
      debugPrint('prepareStyle failed: $e');
    }
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

  Future<void> _onSearchPicked(GeocodeResult r) async {
    final map = _map;
    if (map == null) return;
    final target = LatLng(r.lat, r.lon);
    await map.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
    if (_searchMarker != null) {
      await map.removeCircle(_searchMarker!);
      _searchMarker = null;
    }
    _searchMarker = await map.addCircle(
      CircleOptions(
        geometry: target,
        circleRadius: 8,
        circleColor: '#D32F2F',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
        circleOpacity: 0.9,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.label), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);
    if (_styleStringPath == null || !_permissionResolved) {
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
            myLocationRenderMode: MyLocationRenderMode.normal,
            trackCameraPosition: false,
          ),
          positionAsync.when(
            data: (_) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const Positioned(
              top: 100,
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(28),
                  color: Colors.white.withValues(alpha: 0.85),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SearchField(
                      repo: ref.watch(geocodingRepositoryProvider),
                      onPicked: _onSearchPicked,
                      decoration: const InputDecoration(
                        hintText: 'Search location or road',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
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
