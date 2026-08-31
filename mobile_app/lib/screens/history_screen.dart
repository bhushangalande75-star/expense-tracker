import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/expense.dart';
import '../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = ApiService();
  final _currency = NumberFormat.currency(locale: "en_IN", symbol: "₹");
  late Future<List<Expense>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getExpenses();
  }

  void _refresh() => setState(() => _future = _api.getExpenses());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<List<Expense>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.gold));
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
