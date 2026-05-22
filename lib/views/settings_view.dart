import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../services/color_service.dart';
import '../services/csv_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _categoryController = TextEditingController();

  final TextEditingController _categoriesTextController =
      TextEditingController();

  final Uuid _uuid = const Uuid();

  List<Category> _categories = [];

  bool _loading = false;

  String _selectedType = 'Dépense';

  Color _currentColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _categoriesTextController.dispose();

    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadSavedColor();
    await _loadCategories();
  }

  // ─────────────────────────────────────────────
  // COULEUR DOMINANTE
  // ─────────────────────────────────────────────

  Future<void> _loadSavedColor() async {
    final prefs = await SharedPreferences.getInstance();

    final colorValue = prefs.getInt('base_color');

    if (colorValue != null) {
      final color = Color(colorValue);

      setState(() {
        _currentColor = color;
      });

      ColorService.setBaseColor(color);
    } else {
      _currentColor = ColorService.baseColor;
    }
  }

  Future<void> _saveColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('base_color', color.toARGB32());

    ColorService.setBaseColor(color);
  }

  // ─────────────────────────────────────────────
  // CATÉGORIES
  // ─────────────────────────────────────────────

  Future<void> _loadCategories() async {
    final categories = await CsvService.readAllCategories();

    if (!mounted) return;

    setState(() {
      _categories = categories;
    });

    _updateCategoriesText();
  }

  void _updateCategoriesText() {
    final lines = _categories
        .map((c) => '${c.name}|${c.type}')
        .toList();

    _categoriesTextController.text = lines.join('\n');
  }

  Future<void> _addCategory() async {
    final name = _categoryController.text.trim();

    if (name.isEmpty) {
      return;
    }

    final category = Category(
      id: _uuid.v4(),
      name: name,
      type: _selectedType,
      colorValue: _currentColor.toARGB32(),
    );

    await CsvService.addCategory(category);

    _categoryController.clear();

    await _loadCategories();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catégorie ajoutée')),
    );
  }

  Future<void> _importCategories() async {
    setState(() {
      _loading = true;
    });

    final lines = _categoriesTextController.text.split('\n');

    final importedCategories = <Category>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }

      final parts = line.split('|');

      if (parts.length != 2) {
        continue;
      }

      importedCategories.add(
        Category(
          id: _uuid.v4(),
          name: parts[0].trim(),
          type: parts[1].trim(),
          colorValue: _currentColor.toARGB32(),
        ),
      );
    }

    await CsvService.replaceAllCategories(importedCategories);

    await _loadCategories();

    setState(() {
      _loading = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catégories importées')),
    );
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(
      ClipboardData(text: _categoriesTextController.text),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copié dans le presse-papiers')),
    );
  }

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: _currentColor,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            // ───────── COULEUR ─────────
            const Text(
              'Couleur dominante',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,

                  builder: (context) {
                    Color tempColor = _currentColor;

                    return AlertDialog(
                      title: const Text('Choisir une couleur'),

                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: _currentColor,

                          onColorChanged: (color) {
                            tempColor = color;
                          },
                        ),
                      ),

                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },

                          child: const Text('Annuler'),
                        ),

                        ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              _currentColor = tempColor;
                            });

                            await _saveColor(tempColor);

                            if (!mounted) return;

                            Navigator.pop(context);
                          },

                          child: const Text('Valider'),
                        ),
                      ],
                    );
                  },
                );
              },

              child: Container(
                height: 55,

                decoration: BoxDecoration(
                  color: _currentColor,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Center(
                  child: Text(
                    'Appuyer pour changer la couleur',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ───────── AJOUT CATÉGORIE ─────────
            const Text(
              'Ajouter une catégorie',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,

                    decoration: InputDecoration(
                      labelText: 'Nom de la catégorie',

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                DropdownButton<String>(
                  value: _selectedType,

                  items: ['Dépense', 'Revenu']
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),

                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedType = value;
                    });
                  },
                ),

                IconButton(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add_circle),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ───────── IMPORT / EXPORT ─────────
            const Text(
              'Import / Export des catégories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Format : nom|type',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _categoriesTextController,
              minLines: 8,
              maxLines: 14,

              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _copyToClipboard,
                    child: const Text('Copier'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _importCategories,

                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Importer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}