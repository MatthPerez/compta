import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../widgets/fidelity_card.dart';

class FidelityView extends StatefulWidget {
  const FidelityView({super.key});

  @override
  State<FidelityView> createState() => _FidelityViewState();
}

class _FidelityViewState extends State<FidelityView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _numberController = TextEditingController();

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _importExportController = TextEditingController();

  final List<Map<String, String>> _cards = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _titleController.dispose();
    _importExportController.dispose();

    super.dispose();
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();

    return File('${directory.path}/barcodes.txt');
  }

  Future<void> _loadCards() async {
    final file = await _getFile();

    if (!await file.exists()) {
      await file.create(recursive: true);
    }

    final lines = await file.readAsLines();

    final loadedCards = <Map<String, String>>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final parts = line.split('|');

      if (parts.length >= 2) {
        loadedCards.add({'number': parts[0].trim(), 'title': parts[1].trim()});
      }
    }

    setState(() {
      _cards
        ..clear()
        ..addAll(loadedCards);

      _importExportController.text = lines.join('\n');

      _loading = false;
    });
  }

  Future<void> _addCard() async {
    final number = _numberController.text.trim();

    final title = _titleController.text.trim();

    if (number.isEmpty || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );

      return;
    }

    final file = await _getFile();

    final line = '$number|$title\n';

    await file.writeAsString(line, mode: FileMode.append);

    _numberController.clear();
    _titleController.clear();

    await _loadCards();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Carte ajoutée')));
  }

  Future<void> _saveImportExport() async {
    final file = await _getFile();

    final content = _importExportController.text.trim();

    await file.writeAsString(content);

    await _loadCards();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Import/export sauvegardé')));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,

      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cartes de fidélité'),

          bottom: const TabBar(
            tabs: [
              Tab(text: 'Affichage'),
              Tab(text: 'Ajout de carte'),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            // ───────────────── AFFICHAGE ─────────────────
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _cards.isEmpty
                ? const Center(child: Text('Aucune carte enregistrée'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),

                    itemCount: _cards.length,

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),

                    itemBuilder: (context, index) {
                      final card = _cards[index];

                      return FidelityCard(
                        number: card['number']!,
                        title: card['title']!,
                      );
                    },
                  ),

            // ───────────────── AJOUT ─────────────────
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [
                  TextField(
                    controller: _numberController,

                    decoration: InputDecoration(
                      labelText: 'Numéro',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: _titleController,

                    decoration: InputDecoration(
                      labelText: 'Titre',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: ElevatedButton(
                      onPressed: _addCard,

                      child: const Text('Ajouter la carte'),
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'Import / Export',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  const Text('Une ligne par carte au format : numero|titre'),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _importExportController,

                    minLines: 10,
                    maxLines: 20,

                    decoration: InputDecoration(
                      hintText: '123456789|Carrefour\n987654321|Ikea',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: ElevatedButton(
                      onPressed: _saveImportExport,

                      child: const Text('Sauvegarder import/export'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
