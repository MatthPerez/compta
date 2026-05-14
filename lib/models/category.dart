class Category {
  final String id;
  final String name;
  final String type;
  final int colorValue;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.colorValue,
  });

  String toCsv() {
    return '$id|$name|$type|$colorValue';
  }

  static Category fromCsv(String csvLine) {
    final parts = csvLine.split('|');
    if (parts.length != 4) {
      throw FormatException('Ligne CSV invalide pour la catégorie: $csvLine');
    }
    return Category(
      id: parts[0],
      name: parts[1],
      type: parts[2],
      colorValue: int.parse(parts[3]),
    );
  }
}
