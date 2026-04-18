import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/screens/map_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SofiaBikeNavApp()));
}

class SofiaBikeNavApp extends StatelessWidget {
  const SofiaBikeNavApp({super.key});

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
