class Transaction {
  final String type; // 'Dépense' ou 'Revenu'
  final DateTime date;
  final String designation;
  final double montant;
  final String categorie;

  // Constructeur principal
  Transaction({
    required this.type,
    required this.date,
    required this.designation,
    required this.montant,
    required this.categorie,
  });

  // Convertit la transaction en ligne CSV
  String toCsv() {
    final formattedDate =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return '$type|$formattedDate|$designation|$montant|$categorie';
  }

  // Crée une transaction depuis une ligne CSV
  factory Transaction.fromCsv(String csvLine) {
    final parts = csvLine.split('|');
    if (parts.length != 5) {
      throw FormatException('Ligne CSV invalide: $csvLine');
    }
    return Transaction(
      type: parts[0],
      date: DateTime.parse(
        '${parts[1].substring(0, 4)}-${parts[1].substring(4, 6)}-${parts[1].substring(6, 8)}',
      ),
      designation: parts[2],
      montant: double.parse(parts[3].replaceAll(',', '.')),
      categorie: parts[4],
    );
  }
}
