import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../models/expense.dart';
import '../theme.dart';
import 'add_expense_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = ApiService();
  final _currency = NumberFormat.currency(locale: "en_IN", symbol: "₹");
  late Future<List<Expense>> _future;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _future = _api.getExpenses();
  }

  void _refresh() => setState(() => _future = _api.getExpenses());

  Future<void> _exportReport() async {
    setState(() => _exporting = true);
    try {
      final bytes = await _api.exportExpensesCsv();
      final dir = await getTemporaryDirectory();
      final file = File(
        "${dir.path}/expenses_report_${DateTime.now().millisecondsSinceEpoch}.csv",
      );
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: "Expense report",
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export failed: $e"), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _openEdit(Expense e) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddExpenseScreen(existing: e)),
    );
    if (changed == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        actions: [
          IconButton(
            onPressed: _exporting ? null : _exportReport,
            icon: _exporting
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share),
            tooltip: "Export report",
          ),
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Expense>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.emerald));
          }
          final expenses = snap.data ?? [];
          if (expenses.isEmpty) {
            return const Center(child: Text("No expenses recorded yet"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: expenses.length,
            itemBuilder: (context, i) {
              final e = expenses[i];
              return Dismissible(
                key: Key(e.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _api.deleteExpense(e.id),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () => _openEdit(e),
                    title: Text(e.category.name),
                    subtitle: Text(
                      "${e.expenseDate.toLocal().toString().split(' ').first}"
                      "${e.note != null ? ' · ${e.note}' : ''}",
                    ),
                    trailing: Text(
                      _currency.format(e.amount),
                      style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
