import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/csv_service.dart';
import '../services/color_service.dart';

class AddDataView extends StatefulWidget {
  const AddDataView({super.key});

  @override
  State<AddDataView> createState() => _AddDataViewState();
}

class _AddDataViewState extends State<AddDataView> {
  final _formKey = GlobalKey<FormState>();
  final _designationController = TextEditingController();
  final _montantController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Dépense';
  String? _selectedCategoryId;
  List<Category> _categoryObjects = [];
  List<Transaction> _allTransactions = [];
  final FocusNode _montantFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadCategories();
    await _loadTransactions();
  }

  Future<void> _loadCategories() async {
    final categories = await CsvService.readAllCategories();
    if (mounted) {
      setState(() {
        _categoryObjects = categories
            .where((c) => c.type == _selectedType)
            .toList();
        if (_categoryObjects.isNotEmpty && _selectedCategoryId == null) {
          _selectedCategoryId = _categoryObjects.first.id;
        }
      });
    }
  }

  Future<void> _loadTransactions() async {
    final transactions = await CsvService.readAllTransactions();
    if (mounted) {
      setState(() {
        _allTransactions = transactions;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedCategory = _categoryObjects.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => Category(
        id: 'default',
        name: 'Autre',
        type: _selectedType,
        colorValue: Colors.grey.toARGB32(),
      ),
    );

    final transaction = Transaction(
      type: _selectedType,
      date: _selectedDate,
      designation: _designationController.text.trim(),
      montant: double.parse(_montantController.text.replaceAll(',', '.')),
      categorie: selectedCategory.name,
    );

    await CsvService.addTransaction(transaction);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donnée ajoutée avec succès !')),
    );
    context.go('/');
  }

  @override
  void dispose() {
    _designationController.dispose();
    _montantController.dispose();
    _montantFocusNode.dispose();
    super.dispose();
  }

  List<String> _getSuggestions(String query) {
    return _allTransactions
        .where((t) => t.type == _selectedType)
        .map((t) => t.designation)
        .toSet()
        .where(
          (designation) =>
              designation.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  Future<void> _onDesignationSelected(String selection) async {
    // Met à jour le contrôleur de désignation
    _designationController.text = selection;

    // Trouver la transaction correspondante pour récupérer la catégorie et le montant
    final matchingTransaction = _allTransactions.firstWhere(
      (t) => t.designation == selection && t.type == _selectedType,
      orElse: () => Transaction(
        type: _selectedType,
        date: DateTime.now(),
        designation: '',
        montant: 0.0,
        categorie: 'Autre',
      ),
    );

    if (mounted) {
      // Trouver l'ID de la catégorie correspondante
      final category = _categoryObjects.firstWhere(
        (c) => c.name == matchingTransaction.categorie,
        orElse: () => Category(
          id: 'default',
          name: 'Autre',
          type: _selectedType,
          colorValue: Colors.grey.toARGB32(),
        ),
      );

      setState(() {
        _selectedCategoryId = category.id;
        _montantController.text = matchingTransaction.montant.toStringAsFixed(
          2,
        );
      });
    }

    if (mounted) {
      FocusScope.of(context).requestFocus(_montantFocusNode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajout de données'),
        backgroundColor: ColorService.baseColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Type (Dépense/Revenu)
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: ['Dépense', 'Revenu']
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _selectedCategoryId = null;
                    _loadCategories();
                    _loadTransactions();
                    _designationController.clear();
                    _montantController.clear();
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Date
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Date',
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                  hintText: DateFormat('dd/MM/yyyy').format(_selectedDate),
                ),
                readOnly: true,
                onTap: _pickDate,
                controller: TextEditingController(
                  text: DateFormat('dd/MM/yyyy').format(_selectedDate),
                ),
                validator: (value) => value!.isEmpty ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 16),

              // Désignation avec autocomplétion
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  return _getSuggestions(textEditingValue.text);
                },
                onSelected: _onDesignationSelected,
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      // Synchronise le contrôleur de l'Autocomplete avec _designationController
                      textEditingController.addListener(() {
                        if (textEditingController.text !=
                            _designationController.text) {
                          _designationController.text =
                              textEditingController.text;
                        }
                      });
                      _designationController.addListener(() {
                        if (_designationController.text !=
                            textEditingController.text) {
                          textEditingController.text =
                              _designationController.text;
                        }
                      });
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Désignation',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Obligatoire' : null,
                      );
                    },
              ),
              const SizedBox(height: 16),

              // Montant
              TextFormField(
                focusNode: _montantFocusNode,
                controller: _montantController,
                decoration: const InputDecoration(
                  labelText: 'Montant',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Obligatoire';
                  final montant = double.tryParse(value.replaceAll(',', '.'));
                  if (montant == null || montant <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Catégorie
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                items: _categoryObjects.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 24),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorService.baseColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Ajouter',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
