import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/bike_profile.dart';
import '../../data/models/geocode_result.dart';
import '../../data/models/lat_lng_point.dart';
import '../../state/providers.dart';
import '../../state/route_controller.dart';
import '../widgets/bike_profile_dropdown.dart';
import '../widgets/route_summary_card.dart';
import '../widgets/search_field.dart';
import 'navigation_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  BikeProfile? _profile;
  GeocodeResult? _destination;
  LatLngPoint? _start; // null = use current position

  Future<void> _findRoute() async {
    final dest = _destination;
    final profile = _profile;
    if (dest == null || profile == null) return;

    var start = _start;
    if (start == null) {
      final pos = await ref.read(locationServiceProvider).currentPosition();
      if (pos == null) {
        _snack('Location permission denied');
        return;
      }
      start = LatLngPoint(pos.latitude, pos.longitude);
    }

    await ref.read(routeControllerProvider.notifier).fetch(
          start: start,
          end: LatLngPoint(dest.lat, dest.lon),
          profile: profile.id,
        );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);
    final routeAsync = ref.watch(routeControllerProvider);
    final geocoding = ref.watch(geocodingRepositoryProvider);

    // Initialise _profile once profiles arrive.
    profilesAsync.whenData((list) {
      if (_profile == null && list.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _profile = list.first);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Find route')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InputDecorator(
                decoration: InputDecoration(
                  labelText: 'From:',
                  border: OutlineInputBorder(),
                ),
                child: Text('My location'),
              ),
              const SizedBox(height: 12),
              SearchField(
                repo: geocoding,
                onPicked: (r) => setState(() => _destination = r),
              ),
              const SizedBox(height: 12),
              profilesAsync.when(
                data: (list) => BikeProfileDropdown(
                  profiles: list,
                  selected: _profile,
                  onChanged: (p) => setState(() => _profile = p),
                ),
                loading: () =>
                    const LinearProgressIndicator(minHeight: 2),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _destination == null ? null : _findRoute,
                icon: const Icon(Icons.search),
                label: const Text('Find route'),
              ),
              const SizedBox(height: 16),
              routeAsync.when(
                data: (route) {
                  if (route == null || _profile == null) {
                    return const SizedBox.shrink();
                  }
                  return RouteSummaryCard(
                    route: route,
                    profile: _profile!,
                    onStart: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NavigationScreen(route: route),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No route: $e'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
