import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../commits/services/location_service.dart';
import 'ui/screens/map_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SofiaBikeNavApp()));
}

class SofiaBikeNavApp extends StatefulWidget {
  const SofiaBikeNavApp({super.key});

  @override
  State<SofiaBikeNavApp> createState() => _SofiaBikeNavAppState();
}

class _SofiaBikeNavAppState extends State<SofiaBikeNavApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationService().ensurePermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sofia Bike Nav',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
