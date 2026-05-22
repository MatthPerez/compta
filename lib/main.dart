import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'views/home_view.dart';
import 'views/add_data_view.dart';
import 'views/visualization_view.dart';
import 'views/fidelity_view.dart';
import 'views/settings_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Configuration du router directement dans main.dart
  static final _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeView()),
      GoRoute(
        path: '/add-data',
        builder: (context, state) => const AddDataView(),
      ),
      GoRoute(
        path: '/visualization',
        builder: (context, state) => const VisualizationView(),
      ),
      GoRoute(
        path: '/fidelite',
        builder: (context, state) => const FidelityView(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsView(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Compta',
      debugShowCheckedModeBanner: false,
      routerConfig: _router, // Utilise le router défini localement
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
      ),
    );
  }
}
