import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/transaction.dart';
import '../../services/csv_service.dart';

class ImportExportTab extends StatefulWidget {
  const ImportExportTab({super.key});

  @override
  State<ImportExportTab> createState() => _ImportExportTabState();
}

class _ImportExportTabState extends State<ImportExportTab> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _export();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final transactions = await CsvService.readAllTransactions();
    final lines = transactions.map((t) => t.toCsv()).toList();
    if (mounted) {
      setState(() {
        _controller.text = lines.join('\n');
      });
    }
  }

  Future<void> _updateData() async {
    setState(() => _loading = true);

    final lines = _controller.text.split('\n');
    final transactions = <Transaction>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        transactions.add(Transaction.fromCsv(line));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur de format: $line\nFormat attendu: TYPE|DATE|DÉSIGNATION|MONTANT|CATÉGORIE',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    await CsvService.replaceAllTransactions(transactions);

    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Données mises à jour')));
      await _export();
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copié dans le presse-papiers')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(8),
                    hintText: 'TYPE|DATE|DÉSIGNATION|MONTANT|CATÉGORIE',
                  ),
                  enabled: true,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _copyToClipboard,
                  child: const Text('Copier'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading ? null : _updateData,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Mettre à jour'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
