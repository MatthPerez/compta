import 'package:flutter/material.dart';
import 'visualisation/stats_tab.dart';
import 'visualisation/import_export_tab.dart';

class VisualizationView extends StatefulWidget {
  const VisualizationView({super.key});

  @override
  State<VisualizationView> createState() => _VisualizationViewState();
}

class _VisualizationViewState extends State<VisualizationView> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Visualisation des données'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Statistiques'),
              Tab(text: 'Import/Export'),
            ],
          ),
        ),
        body: const TabBarView(children: [StatsTab(), ImportExportTab()]),
      ),
    );
  }
}
