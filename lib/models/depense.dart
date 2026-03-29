class Depense {
  final DateTime date;
  final String designation;
  final double valeur;
  final String categorie;

  const Depense({
    required this.date,
    required this.designation,
    required this.valeur,
    required this.categorie,
  });

  factory Depense.fromCsv(String line) {
    final parts = line.split(';');
    return Depense(
      date:        DateTime.parse(parts[0].trim()),
      designation: parts[1].trim(),
      valeur:      double.parse(parts[2].trim()),
      categorie:   parts[3].trim(),
    );
  }

  String toCsv() {
    final dateStr = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '$dateStr;$designation;${valeur.toStringAsFixed(2)};$categorie';
  }
}