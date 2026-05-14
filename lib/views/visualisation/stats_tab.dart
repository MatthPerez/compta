import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/transaction.dart';
import '../../services/csv_service.dart';
import '../../services/color_service.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  List<Transaction> _transactions = [];
  bool _loading = true;

  int? _selectedYear;
  int? _selectedMonth;
  int? _touchedIndexDepense;
  int? _touchedIndexRevenu;

  final List<Color> _colors = [
    ColorService.baseColor,
    ColorService.lightColor,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  final List<String> _months = const [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final transactions = await CsvService.readAllTransactions();
    setState(() {
      _transactions = transactions;
      _loading = false;
    });
  }

  List<Transaction> get _filteredTransactions {
    return _transactions.where((t) {
      if (_selectedYear != null && t.date.year != _selectedYear) return false;
      if (_selectedMonth != null && t.date.month != _selectedMonth)
        return false;
      return true;
    }).toList();
  }

  List<Transaction> get _depenses =>
      _filteredTransactions.where((t) => t.type == 'Dépense').toList();
  List<Transaction> get _revenus =>
      _filteredTransactions.where((t) => t.type == 'Revenu').toList();

  double get _totalDepenses => _depenses.fold(0.0, (a, b) => a + b.montant);
  double get _totalRevenus => _revenus.fold(0.0, (a, b) => a + b.montant);
  double get _solde => _totalRevenus - _totalDepenses;

  List<int> get _years {
    return _transactions.map((t) => t.date.year).toSet().toList()..sort();
  }

  List<int> get _monthsAvailable {
    return _filteredTransactions.map((t) => t.date.month).toSet().toList()
      ..sort();
  }

  Map<String, double> _groupByCategory(List<Transaction> transactions) {
    final map = <String, double>{};
    for (final t in transactions) {
      map[t.categorie] = (map[t.categorie] ?? 0) + t.montant;
    }
    return map;
  }

  // Méthode pour obtenir les revenus par mois pour l'année sélectionnée
  Map<int, double> _getMonthlyRevenusForSelectedYear() {
    final selectedYear = _selectedYear ?? DateTime.now().year;
    final monthlyRevenus = <int, double>{};
    for (int month = 1; month <= 12; month++) {
      monthlyRevenus[month] = 0.0;
    }

    for (final t in _transactions.where(
      (t) => t.type == 'Revenu' && t.date.year == selectedYear,
    )) {
      monthlyRevenus[t.date.month] =
          (monthlyRevenus[t.date.month] ?? 0) + t.montant;
    }

    return monthlyRevenus;
  }

  // Méthode pour obtenir les revenus par mois pour l'année en cours
  Map<int, double> _getMonthlyRevenusCurrentYear() {
    final now = DateTime.now();
    final monthlyRevenus = <int, double>{};
    for (int month = 1; month <= 12; month++) {
      monthlyRevenus[month] = 0.0;
    }

    for (final t in _transactions.where(
      (t) => t.type == 'Revenu' && t.date.year == now.year,
    )) {
      monthlyRevenus[t.date.month] =
          (monthlyRevenus[t.date.month] ?? 0) + t.montant;
    }

    return monthlyRevenus;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final monthlyRevenusCurrentYear = _getMonthlyRevenusCurrentYear();
    final hasRevenusCurrentYear = monthlyRevenusCurrentYear.values.any(
      (value) => value > 0,
    );

    final monthlyRevenusSelectedYear = _getMonthlyRevenusForSelectedYear();
    final hasRevenusSelectedYear = monthlyRevenusSelectedYear.values.any(
      (value) => value > 0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Bloc fixe pour la sélection de période
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorService.lightColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Année',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Toutes'),
                      ),
                      ..._years.map(
                        (y) => DropdownMenuItem(value: y, child: Text('$y')),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value;
                        _selectedMonth = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Mois',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous')),
                      ..._monthsAvailable.map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(_months[m - 1]),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedMonth = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Totaux
          _card(
            child: Column(
              children: [
                _line('Revenus', _totalRevenus, color: Colors.green),
                _line('Dépenses', _totalDepenses, color: Colors.red),
                const Divider(),
                _line('Solde', _solde, bold: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Graphique pour les dépenses (avec titre au clic)
          if (_depenses.isNotEmpty) ...[
            _pieChartCard(
              title: 'Répartition des dépenses',
              data: _groupByCategory(_depenses),
              total: _totalDepenses,
              touchedIndex: _touchedIndexDepense,
              onSectionTouched: (index) {
                setState(() => _touchedIndexDepense = index);
              },
            ),
            const SizedBox(height: 16),
          ],

          // Graphique pour les revenus (avec titre au clic)
          if (_revenus.isNotEmpty) ...[
            _pieChartCard(
              title: 'Répartition des revenus',
              data: _groupByCategory(_revenus),
              total: _totalRevenus,
              touchedIndex: _touchedIndexRevenu,
              onSectionTouched: (index) {
                setState(() => _touchedIndexRevenu = index);
              },
            ),
            const SizedBox(height: 16),
          ],

          // Graphique en histogrammes pour les revenus par mois (année en cours)
          if (hasRevenusCurrentYear) ...[
            _barChartCard(
              title: 'Revenus mensuels (${DateTime.now().year})',
              monthlyData: monthlyRevenusCurrentYear,
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _pieChartCard({
    required String title,
    required Map<String, double> data,
    required double total,
    required int? touchedIndex,
    required Function(int?) onSectionTouched,
  }) {
    return _card(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 48,
                pieTouchData: PieTouchData(
                  touchCallback:
                      (FlTouchEvent event, PieTouchResponse? response) {
                        if (response != null &&
                            response.touchedSection != null) {
                          onSectionTouched(
                            response.touchedSection!.touchedSectionIndex,
                          );
                        }
                      },
                ),
                sections: data.entries.toList().asMap().entries.map((e) {
                  final index = e.key;
                  final category = e.value.key;
                  final value = e.value.value;
                  final pct = total == 0 ? 0 : (value / total) * 100;
                  final isTouched = index == touchedIndex;
                  final color = _colors[index % _colors.length];

                  return PieChartSectionData(
                    color: color,
                    value: value,
                    title: isTouched ? category : '',
                    radius: isTouched ? 70 : 60,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    badgeWidget: isTouched
                        ? Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    badgePositionPercentageOffset: 1.2,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: data.entries.map((e) {
              final index = data.keys.toList().indexOf(e.key);
              final pct = total == 0 ? 0 : (e.value / total) * 100;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _colors[index % _colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${e.key}: ${pct.toStringAsFixed(1)}% (${e.value.toStringAsFixed(2)} €)',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _barChartCard({
    required String title,
    required Map<int, double> monthlyData,
  }) {
    final values = monthlyData.values.toList();
    final minValue = values.isNotEmpty
        ? values.reduce((a, b) => a < b ? a : b)
        : 0.0;
    final maxValue = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 1.0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.1,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (response != null && response.spot != null) {
                      final monthIndex = response.spot!.touchedBarGroupIndex;
                      final monthName = _months[monthIndex];
                      final amount = monthlyData[monthIndex + 1]!;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$monthName: ${amount.toStringAsFixed(2)} €',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < 12) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              _months[value.toInt()].substring(0, 3),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: maxValue - minValue,
                      getTitlesWidget: (value, meta) {
                        if (value == minValue || value == maxValue) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              '${value.toStringAsFixed(0)} €',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                barGroups: monthlyData.entries.map((e) {
                  return BarChartGroupData(
                    x: e.key - 1,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: ColorService.baseColor,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, double value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${value.toStringAsFixed(2)} €',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(40, 0, 0, 0),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
