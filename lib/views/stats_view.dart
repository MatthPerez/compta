import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/colors.dart';
import '../models/depense.dart';
import '../services/csv_service.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  List<Depense> _depenses = [];
  bool _loading = true;
  int? _touchedIndex;

  // ── Filtres ──────────────────────────────────────────────
  int? _selectedYear;
  int? _selectedMonth;

  final List<Color> _palette = const [
    Color(0xFF6C63FF),
    Color(0xFF9C94FF),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFFF87171),
    Color(0xFF60A5FA),
    Color(0xFFf472b6),
    Color(0xFFa78bfa),
  ];

  final List<String> _moisLabels = const [
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
    final depenses = await CsvService.readAll();
    setState(() {
      _depenses = depenses;
      _loading = false;
    });
  }

  // ── Années disponibles ───────────────────────────────────
  List<int> get _anneesDisponibles {
    final years = _depenses.map((d) => d.date.year).toSet().toList();
    years.sort();
    return years;
  }

  // ── Mois disponibles selon l'année sélectionnée ──────────
  List<int> get _moisDisponibles {
    final source = _selectedYear == null
        ? _depenses
        : _depenses.where((d) => d.date.year == _selectedYear).toList();
    final months = source.map((d) => d.date.month).toSet().toList();
    months.sort();
    return months;
  }

  // ── Dépenses filtrées ────────────────────────────────────
  List<Depense> get _depensesFiltrees {
    return _depenses.where((d) {
      if (_selectedYear != null && d.date.year != _selectedYear) return false;
      if (_selectedMonth != null && d.date.month != _selectedMonth)
        return false;
      return true;
    }).toList();
  }

  // ── Stats par catégorie ──────────────────────────────────
  Map<String, List<Depense>> _parCategorie(List<Depense> liste) {
    final map = <String, List<Depense>>{};
    for (final d in liste) {
      map.putIfAbsent(d.categorie, () => []).add(d);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  double _min(List<Depense> list) =>
      list.map((d) => d.valeur).reduce((a, b) => a < b ? a : b);
  double _max(List<Depense> list) =>
      list.map((d) => d.valeur).reduce((a, b) => a > b ? a : b);
  double _moy(List<Depense> list) =>
      list.map((d) => d.valeur).reduce((a, b) => a + b) / list.length;
  double _total(List<Depense> list) =>
      list.map((d) => d.valeur).reduce((a, b) => a + b);

  double get _totalGeneral {
    final f = _depensesFiltrees;
    return f.isEmpty ? 0 : f.map((d) => d.valeur).reduce((a, b) => a + b);
  }

  // ── Titre de la période sélectionnée ────────────────────
  String get _titrePeriode {
    if (_selectedYear == null) return 'Toutes périodes';
    if (_selectedMonth == null) return '$_selectedYear';
    return '${_moisLabels[_selectedMonth! - 1]} $_selectedYear';
  }

  @override
  Widget build(BuildContext context) {
    final filtrees = _depensesFiltrees;
    final categories = _parCategorie(filtrees);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Statistiques',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _depenses.isEmpty
          ? const Center(
              child: Text(
                'Aucune dépense enregistrée.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Sélecteurs période ───────────────
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Période',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Sélecteur année
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                value: _selectedYear,
                                decoration: _dropDecoration('Année'),
                                dropdownColor: AppColors.surface,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Toutes'),
                                  ),
                                  ..._anneesDisponibles.map(
                                    (y) => DropdownMenuItem(
                                      value: y,
                                      child: Text('$y'),
                                    ),
                                  ),
                                ],
                                onChanged: (val) => setState(() {
                                  _selectedYear = val;
                                  _selectedMonth = null;
                                }),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Sélecteur mois
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                value: _selectedMonth,
                                decoration: _dropDecoration('Mois'),
                                dropdownColor: AppColors.surface,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('Tous'),
                                  ),
                                  ..._moisDisponibles.map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(_moisLabels[m - 1]),
                                    ),
                                  ),
                                ],
                                onChanged: _selectedYear == null
                                    ? null
                                    : (val) =>
                                          setState(() => _selectedMonth = val),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Total période ────────────────────
                  _card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _titrePeriode,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_totalGeneral.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Graphique camembert ──────────────
                  if (filtrees.isNotEmpty) ...[
                    _card(
                      child: Column(
                        children: [
                          Text(
                            'Répartition — $_titrePeriode',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 240,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 48,
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, response) {
                                    setState(() {
                                      _touchedIndex = response
                                          ?.touchedSection
                                          ?.touchedSectionIndex;
                                    });
                                  },
                                ),
                                sections: _buildSections(
                                  categories,
                                  _totalGeneral,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: categories.keys
                                .toList()
                                .asMap()
                                .entries
                                .map(
                                  (e) => _legendItem(
                                    e.value,
                                    _palette[e.key % _palette.length],
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Stats par catégorie ──────────
                    ...categories.entries.map((entry) {
                      final cat = entry.key;
                      final list = entry.value;
                      final index = categories.keys.toList().indexOf(cat);
                      final color = _palette[index % _palette.length];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête
                              Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${list.length} dépense${list.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),

                              const Divider(height: 20),

                              // Min / Moy / Max / Total
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _statItem('Min', _min(list)),
                                  _statItem('Moy', _moy(list)),
                                  _statItem('Max', _max(list)),
                                  _statItem('Total', _total(list), bold: true),
                                ],
                              ),

                              const Divider(height: 20),

                              // Liste dépenses
                              ...list.map(
                                (d) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          d.designation,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${d.valeur.toStringAsFixed(2)} €',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ] else
                    _card(
                      child: Center(
                        child: Text(
                          'Aucune dépense pour $_titrePeriode.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  // ── Sections camembert ───────────────────────────────────
  List<PieChartSectionData> _buildSections(
    Map<String, List<Depense>> categories,
    double total,
  ) {
    return categories.entries.toList().asMap().entries.map((e) {
      final index = e.key;
      final cat = e.value.key;
      final list = e.value.value;
      final t = _total(list);
      final pct = t / total * 100;
      final isTouched = index == _touchedIndex;
      final color = _palette[index % _palette.length];

      return PieChartSectionData(
        color: color,
        value: t,
        title: '${pct.toStringAsFixed(1)}%',
        radius: isTouched ? 70 : 56,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cat,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  // ── Carte ────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  // ── Stat item ────────────────────────────────────────────
  Widget _statItem(String label, double value, {bool bold = false}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(2)} €',
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ── Légende ──────────────────────────────────────────────
  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  // ── Décoration dropdown ──────────────────────────────────
  InputDecoration _dropDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
