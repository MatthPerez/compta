import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../services/csv_service.dart';
import '../services/color_service.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _categoryController = TextEditingController();
  final _categoriesTextController = TextEditingController();
  String _selectedType = 'Dépense';
  Color _currentColor = ColorService.baseColor;
  List<Category> _categories = [];
  final Uuid _uuid = const Uuid();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await CsvService.readAllCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _updateCategoriesText();
      });
    }
  }

  // Met à jour le texte du bloc d'import/export avec les catégories actuelles
  void _updateCategoriesText() {
    final lines = _categories.map((c) => '${c.name}|${c.type}').toList();
    _categoriesTextController.text = lines.join('\n');
  }

  Future<void> _addCategory() async {
    if (_categoryController.text.isEmpty) return;

    final category = Category(
      id: _uuid.v4(),
      name: _categoryController.text.trim(),
      type: _selectedType,
      colorValue: _currentColor.toARGB32(),
    );

    await CsvService.addCategory(category);
    if (mounted) {
      _categoryController.clear();
      await _loadCategories();
    }
  }

  Future<void> _importCategories() async {
    setState(() => _loading = true);

    final lines = _categoriesTextController.text.split('\n');
    final newCategories = <Category>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.split('|');
      if (parts.length != 2) continue;

      newCategories.add(
        Category(
          id: _uuid.v4(), // Nouvel ID unique pour chaque catégorie importée
          name: parts[0].trim(),
          type: parts[1].trim(),
          colorValue: _currentColor.toARGB32(), // Couleur par défaut
        ),
      );
    }

    await CsvService.replaceAllCategories(newCategories);
    if (mounted) {
      await _loadCategories();
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Catégories importées')));
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(
      ClipboardData(text: _categoriesTextController.text),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copié dans le presse-papiers')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: ColorService.baseColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sélection de la couleur dominante
            const Text(
              'Couleur dominante',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Sélectionner une couleur'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: _currentColor,
                          onColorChanged: (color) {
                            setState(() => _currentColor = color);
                            ColorService.setBaseColor(color);
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: _currentColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Center(
                  child: Text(
                    'Appuyez pour choisir une couleur',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ajout d'une catégorie
            const Text(
              'Ajouter une catégorie',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la catégorie',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedType,
                  items: ['Dépense', 'Revenu']
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedType = value!);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addCategory,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bloc d'import/export des catégories
            const Text(
              'Import/Export des catégories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Format: category|type (ex: Loyer|Dépense)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _categoriesTextController,
                maxLines: 8,
                minLines: 5,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                        ? const CircularProgressIndicator()
                        : const Text('Importer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
