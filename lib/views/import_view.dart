import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../models/depense.dart';
import '../services/csv_service.dart';

class ImportView extends StatefulWidget {
  const ImportView({super.key});

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  final _csvController = TextEditingController();
  bool _loading = false;
  String? _previewContent;

  // ── Charger le contenu actuel du CSV ─────────────────────
  Future<void> _loadPreview() async {
    setState(() => _loading = true);
    final depenses = await CsvService.readAll();
    setState(() {
      _previewContent = depenses.isEmpty
          ? '(fichier vide)'
          : depenses.map((d) => d.toCsv()).join('\n');
      _loading = false;
    });
  }

  // ── Copier dans le presse-papier ─────────────────────────
  Future<void> _copyToClipboard() async {
    if (_previewContent == null || _previewContent == '(fichier vide)') {
      await _loadPreview();
    }
    if (_previewContent == null) return;

    await Clipboard.setData(ClipboardData(text: _previewContent!));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contenu copié dans le presse-papier !'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  // ── Valider une ligne CSV ─────────────────────────────────
  Depense? _parseLigne(String line) {
    final parts = line.trim().split(';');
    if (parts.length != 4) return null;
    try {
      final date = DateTime.parse(parts[0].trim());
      final designation = parts[1].trim();
      final valeur = double.parse(parts[2].trim().replaceAll(',', '.'));
      final categorie = parts[3].trim();
      if (designation.isEmpty || categorie.isEmpty || valeur <= 0) return null;
      return Depense(
        date: date,
        designation: designation,
        valeur: valeur,
        categorie: categorie,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Importer le CSV saisi ─────────────────────────────────
  Future<void> _importer() async {
    final texte = _csvController.text.trim();
    if (texte.isEmpty) {
      _showSnack('Le champ est vide.', AppColors.warning);
      return;
    }

    final lignes = texte.split('\n');
    final valides = <Depense>[];
    final invalides = <int>[];

    for (int i = 0; i < lignes.length; i++) {
      final ligne = lignes[i].trim();
      if (ligne.isEmpty) continue;
      final depense = _parseLigne(ligne);
      if (depense != null) {
        valides.add(depense);
      } else {
        invalides.add(i + 1); // numéro de ligne (base 1)
      }
    }

    if (valides.isEmpty) {
      _showSnack(
        'Aucune ligne valide trouvée. Format attendu :\nAAAA-MM-JJ;désignation;valeur;catégorie',
        AppColors.error,
      );
      return;
    }

    // Confirmation si des lignes sont invalides
    if (invalides.isNotEmpty) {
      final continuer = await _showConfirmDialog(invalides);
      if (!continuer) return;
    }

    setState(() => _loading = true);

    await CsvService.replaceAll(valides);

    // Recharger la preview
    await _loadPreview();

    setState(() => _loading = false);
    _csvController.clear();

    if (mounted) {
      _showSnack(
        '${valides.length} ligne(s) importée(s) avec succès.',
        AppColors.success,
      );
    }
  }

  // ── Dialog de confirmation lignes invalides ───────────────
  Future<bool> _showConfirmDialog(List<int> lignesInvalides) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Lignes invalides',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Les lignes suivantes sont invalides et seront ignorées :\n'
          'Lignes : ${lignesInvalides.join(', ')}\n\n'
          'Continuer avec les lignes valides ?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Import / Export CSV',
          style: TextStyle(color: AppColors.textOnPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Bloc export / presse-papier ──────
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Contenu actuel',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Rafraîchir
                                    IconButton(
                                      onPressed: _loadPreview,
                                      icon: const Icon(
                                        Icons.refresh,
                                        color: AppColors.primary,
                                      ),
                                      tooltip: 'Rafraîchir',
                                    ),
                                    // Copier
                                    ElevatedButton.icon(
                                      onPressed: _copyToClipboard,
                                      icon: const Icon(Icons.copy, size: 16),
                                      label: const Text('Copier'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor:
                                            AppColors.textOnPrimary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Aperçu du contenu
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: SingleChildScrollView(
                                child: Text(
                                  _previewContent ?? 'Chargement...',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: AppColors.textPrimary,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Bloc import ──────────────────────
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Importer des données',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Format attendu
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Text(
                                'Format attendu (une ligne par dépense) :\n'
                                'AAAA-MM-JJ;désignation;valeur;catégorie\n\n'
                                'Exemple :\n'
                                '2024-03-15;Courses supermarché;52.30;Alimentation\n'
                                '2024-03-16;Essence;45.00;Transport',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Zone de saisie CSV
                            TextFormField(
                              controller: _csvController,
                              maxLines: 8,
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                color: AppColors.textPrimary,
                                height: 1.6,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Collez ou saisissez vos données CSV ici...',
                                hintStyle: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Boutons
                            Row(
                              children: [
                                // Effacer
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _csvController.clear(),
                                    // icon: const Icon(
                                    //   Icons.clear,
                                    //   color: AppColors.textSecondary,
                                    // ),
                                    label: const Text(
                                      '❌',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize: const Size(
                                        double.infinity,
                                        48,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Importer
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: _importer,
                                    icon: const Icon(Icons.upload),
                                    label: const Text(
                                      'Importer',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textOnPrimary,
                                      minimumSize: const Size(
                                        double.infinity,
                                        48,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
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
}
