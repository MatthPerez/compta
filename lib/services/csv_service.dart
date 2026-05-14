import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart' as custom_category;

class CsvService {
  static const String _dataFileName = 'compta.csv';
  static const String _categoriesFileName = 'categories.csv';
  static late Directory _datasDir;
  static late File _dataFile;
  static late File _categoriesFile;

  static Future<void> _init() async {
    final dir = await getApplicationDocumentsDirectory();
    _datasDir = Directory('${dir.path}/datas');
    if (!await _datasDir.exists()) {
      await _datasDir.create(recursive: true);
    }
    _dataFile = File('${_datasDir.path}/$_dataFileName');
    _categoriesFile = File('${_datasDir.path}/$_categoriesFileName');
  }

  static Future<List<Transaction>> readAllTransactions() async {
    await _init();
    if (!await _dataFile.exists()) return [];

    final lines = await _dataFile.readAsLines();
    final transactions = <Transaction>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        transactions.add(Transaction.fromCsv(line));
      } catch (e) {
        if (kDebugMode) {
          print('Erreur de lecture de la ligne: $line');
        }
      }
    }

    return transactions;
  }

  static Future<void> addTransaction(Transaction t) async {
    await _init();
    await _dataFile.writeAsString('${t.toCsv()}\n', mode: FileMode.append);
  }

  static Future<void> replaceAllTransactions(
    List<Transaction> transactions,
  ) async {
    await _init();
    final content = transactions.map((t) => t.toCsv()).join('\n');
    await _dataFile.writeAsString(content);
  }

  static Future<List<custom_category.Category>> readAllCategories() async {
    await _init();
    if (!await _categoriesFile.exists()) return [];

    final lines = await _categoriesFile.readAsLines();
    final categories = <custom_category.Category>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        categories.add(custom_category.Category.fromCsv(line));
      } catch (e) {
        if (kDebugMode) {
          print('Erreur de lecture de la catégorie: $line');
        }
      }
    }

    return categories;
  }

  static Future<void> addCategory(custom_category.Category c) async {
    await _init();
    await _categoriesFile.writeAsString(
      '${c.toCsv()}\n',
      mode: FileMode.append,
    );
  }

  static Future<void> replaceAllCategories(
    List<custom_category.Category> categories,
  ) async {
    await _init();
    final content = categories.map((c) => c.toCsv()).join('\n');
    await _categoriesFile.writeAsString(content);
  }

  static Future<List<String>> getDesignations(String type) async {
    final transactions = await readAllTransactions();
    return transactions
        .where((t) => t.type == type)
        .map((t) => t.designation)
        .toSet()
        .toList();
  }

  static Future<String> getCategoryForDesignation(
    String designation,
    String type,
  ) async {
    final transactions = await readAllTransactions();
    try {
      final transaction = transactions.firstWhere(
        (t) => t.designation == designation && t.type == type,
      );
      return transaction.categorie;
    } catch (e) {
      return 'Autre';
    }
  }
}
