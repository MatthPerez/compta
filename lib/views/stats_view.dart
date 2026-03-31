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

  // ── Catégories déployées ─────────────────────────────────
  final Set<String> _expandedCategories = {};

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

  List<int> get _anneesDisponibles {
    final years = _depenses.map((d) => d.date.year).toSet().toList();
    years.sort();
    return years;
  }

  List<int> get _moisDisponibles {
    final source = _selectedYear == null
        ? _depenses
        : _depenses.where((d) => d.date.year == _selectedYear).toList();
    final months = source.map((d) => d.date.month).toSet().toList();
    months.sort();
    return months;
  }

  List<Depense> get _depensesFiltrees {
    return _depenses.where((d) {
      if (_selectedYear != null && d.date.year != _selectedYear) return false;
      if (_selectedMonth != null && d.date.month != _selectedMonth)
        return false;
      return true;
    }).toList();
  }

  List<Depense> get _loyersAnnee {
    final source = _selectedYear == null
        ? _depenses
        : _depenses.where((d) => d.date.year == _selectedYear).toList();
    final loyers = source
        .where((d) => d.designation.toLowerCase().contains('loyer'))
        .toList();
    loyers.sort((a, b) => a.date.compareTo(b.date));
    return loyers;
  }

  double get _totalLoyers {
    final loyers = _loyersAnnee;
    if (loyers.isEmpty) return 0;
    return loyers.map((d) => d.valeur).reduce((a, b) => a + b);
  }

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

  String get _titrePeriode {
    if (_selectedYear == null) return 'Toutes périodes';
    if (_selectedMonth == null) return '$_selectedYear';
    return '${_moisLabels[_selectedMonth! - 1]} $_selectedYear';
  }

  String get _titreAnneeLoyers {
    if (_selectedYear == null) return 'Toutes périodes';
    return '$_selectedYear';
  }

  // ── Bloc période figé ────────────────────────────────────
  Widget _buildPeriodeBar() {
    return Material(
      color: AppColors.background,
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: _selectedYear,
                decoration: _dropDecoration('Année'),
                dropdownColor: AppColors.surface,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes')),
                  ..._anneesDisponibles.map(
                    (y) => DropdownMenuItem(value: y, child: Text('$y')),
                  ),
                ],
                onChanged: (val) => setState(() {
                  _selectedYear = val;
                  _selectedMonth = null;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: _selectedMonth,
                decoration: _dropDecoration('Mois'),
                dropdownColor: AppColors.surface,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tous')),
                  ..._moisDisponibles.map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(_moisLabels[m - 1]),
                    ),
                  ),
                ],
                onChanged: _selectedYear == null
                    ? null
                    : (val) => setState(() => _selectedMonth = val),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrees = _depensesFiltrees;
    final categories = _parCategorie(filtrees);
    final loyers = _loyersAnnee;

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
          : Column(
              children: [
                // ── Bloc période figé ────────────────
                _buildPeriodeBar(),

                // ── Contenu scrollable ───────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Total période ────────────
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

                        if (filtrees.isNotEmpty) ...[
                          // ── Graphique camembert ──────
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

                          // ── Blocs catégorie déployables ──
                          ...categories.entries.map((entry) {
                            final cat = entry.key;
                            final list = entry.value;
                            final index = categories.keys.toList().indexOf(cat);
                            final color = _palette[index % _palette.length];
                            final isExpanded = _expandedCategories.contains(
                              cat,
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── En-tête cliquable ──
                                    InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => setState(() {
                                        if (isExpanded) {
                                          _expandedCategories.remove(cat);
                                        } else {
                                          _expandedCategories.add(cat);
                                        }
                                      }),
                                      child: Row(
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
                                          const SizedBox(width: 8),
                                          Text(
                                            '${_total(list).toStringAsFixed(2)} €',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          AnimatedRotation(
                                            turns: isExpanded ? 0.5 : 0,
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            child: Icon(
                                              Icons.keyboard_arrow_down,
                                              color: color,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // ── Contenu déployable ──
                                    AnimatedCrossFade(
                                      firstChild: const SizedBox(
                                        width: double.infinity,
                                      ),
                                      secondChild: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Divider(height: 20),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              _statItem('Min', _min(list)),
                                              _statItem('Moy', _moy(list)),
                                              _statItem('Max', _max(list)),
                                              _statItem(
                                                'Total',
                                                _total(list),
                                                bold: true,
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 20),
                                          ...list.map(
                                            (d) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 3,
                                                  ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      d.designation,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${d.valeur.toStringAsFixed(2)} €',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      crossFadeState: isExpanded
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      duration: const Duration(
                                        milliseconds: 250,
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

                        const SizedBox(height: 16),

                        // ── Tableau récapitulatif des loyers ─
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.home_outlined,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Loyers — $_titreAnneeLoyers',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              loyers.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Text(
                                          'Aucun loyer trouvé pour $_titreAnneeLoyers.',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: const Row(
                                            children: [
                                              SizedBox(
                                                width: 90,
                                                child: Text(
                                                  'Date',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  'Désignation',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 80,
                                                child: Text(
                                                  'Montant',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ...loyers.asMap().entries.map((entry) {
                                          final i = entry.key;
                                          final d = entry.value;
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: i.isEven
                                                  ? Colors.transparent
                                                  : AppColors.primary
                                                        .withValues(
                                                          alpha: 0.03,
                                                        ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 90,
                                                  child: Text(
                                                    '${d.date.day.toString().padLeft(2, '0')}/'
                                                    '${d.date.month.toString().padLeft(2, '0')}/'
                                                    '${d.date.year}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    d.designation,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 80,
                                                  child: Text(
                                                    '${d.valeur.toStringAsFixed(2)} €',
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        const Divider(height: 16),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 90),
                                              const Expanded(
                                                child: Text(
                                                  'Total loyers',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 80,
                                                child: Text(
                                                  '${_totalLoyers.toStringAsFixed(2)} €',
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

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
