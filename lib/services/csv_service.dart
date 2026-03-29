import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/depense.dart';

class CsvService {
  CsvService._();

  static const String _fileName = 'compta.csv';

  static Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<List<Depense>> readAll() async {
    try {
      final file = await _file;
      if (!await file.exists()) return [];
      final lines = await file.readAsLines();
      return lines
          .where((line) => line.trim().isNotEmpty)
          .map((line) => Depense.fromCsv(line))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeAll(List<Depense> depenses) async {
    final file = await _file;
    depenses.sort((a, b) {
      final dateComp = a.date.compareTo(b.date);
      if (dateComp != 0) return dateComp;
      return a.designation.toLowerCase().compareTo(b.designation.toLowerCase());
    });
    final lines = depenses.map((d) => d.toCsv()).join('\n');
    await file.writeAsString(lines);
  }

  static Future<void> add(Depense depense) async {
    final depenses = await readAll();
    depenses.add(depense);
    await _writeAll(depenses);
  }
  static Future<List<Depense>> getSuggestions(String query) async {
    final depenses = await readAll();
    final seen = <String>{};
    final unique = <Depense>[];
    for (final d in depenses) {
      if (d.designation.toLowerCase().contains(query.toLowerCase()) &&
          seen.add(d.designation.toLowerCase())) {
        unique.add(d);
      }
    }
    return unique;
  }
}
