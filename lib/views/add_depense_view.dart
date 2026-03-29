import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../constants/colors.dart';
import '../models/depense.dart';
import '../services/csv_service.dart';

class AddDepenseView extends StatefulWidget {
  const AddDepenseView({super.key});

  @override
  State<AddDepenseView> createState() => _AddDepenseViewState();
}

class _AddDepenseViewState extends State<AddDepenseView> {
  final _formKey = GlobalKey<FormState>();

  // ── Contrôleurs ──────────────────────────────────────────
  final _designationController = TextEditingController();
  final _valeurController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategorie;

  final List<String> _categories = [
    'Alimentation',
    'Beauté',
    'Chats',
    'Transport',
    'Logement',
    'Vêtements',
    'Magasins',
    'Restaurants',
    'Santé',
    'Bébé',
    'Loisirs',
    'Professionnel',
    'Services',
    'Autre',
  ];

  // ── Date picker ──────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Soumission ───────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final depense = Depense(
      date: _selectedDate,
      designation: _designationController.text.trim(),
      valeur: double.parse(_valeurController.text.trim().replaceAll(',', '.')),
      categorie: _selectedCategorie ?? '',
    );

    await CsvService.add(depense);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dépense enregistrée !'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/');
    }
  }

  @override
  void dispose() {
    _designationController.dispose();
    _valeurController.dispose();
    super.dispose();
  }

  // ── Style commun des champs ──────────────────────────────
  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Ajouter une dépense',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.95,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Date ────────────────────────────
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: _inputDecoration(
                              'Date',
                              suffixIcon: const Icon(
                                Icons.calendar_today,
                                color: AppColors.primary,
                              ),
                            ),
                            controller: TextEditingController(
                              text: DateFormat(
                                'dd/MM/yyyy',
                              ).format(_selectedDate),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Désignation + autocomplétion ────
                      TypeAheadField<Depense>(
                        controller: _designationController,
                        suggestionsCallback: (query) async {
                          if (query.length < 2) return [];
                          return CsvService.getSuggestions(query);
                        },
                        itemBuilder: (context, depense) {
                          return ListTile(
                            title: Text(depense.designation),
                            subtitle: Text(
                              '${depense.valeur.toStringAsFixed(2)} € — ${depense.categorie}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        onSelected: (depense) {
                          // Préremplissage à la sélection uniquement
                          _designationController.text = depense.designation;
                          _valeurController.text = depense.valeur
                              .toStringAsFixed(2);
                          setState(
                            () => _selectedCategorie = depense.categorie,
                          );
                        },
                        builder: (context, controller, focusNode) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: _inputDecoration('Désignation'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Champ obligatoire'
                                : null,
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── Valeur ──────────────────────
                      TextFormField(
                        controller: _valeurController,
                        decoration: _inputDecoration(
                          'Valeur',
                          suffixIcon: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              '€',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Champ obligatoire';
                          }
                          final parsed = double.tryParse(
                            v.replaceAll(',', '.'),
                          );
                          if (parsed == null || parsed <= 0) {
                            return 'Valeur invalide';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── Catégorie ───────────────────────
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategorie,
                        decoration: _inputDecoration('Catégorie'),
                        dropdownColor: AppColors.surface,
                        items: _categories
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCategorie = val),
                        validator: (v) =>
                            v == null ? 'Champ obligatoire' : null,
                      ),

                      const SizedBox(height: 32),

                      // ── Bouton OK ───────────────────────
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
