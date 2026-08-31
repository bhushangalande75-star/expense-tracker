import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/expense.dart';
import '../theme.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  List<Category> _categories = [];
  Category? _selected;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _api.getCategories();
    setState(() {
      _categories = cats;
      _selected = cats.isNotEmpty ? cats.first : null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selected == null) return;
    setState(() => _saving = true);
    try {
      await _api.createExpense(
        categoryId: _selected!.id,
        amount: double.parse(_amountController.text),
        date: _date,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );
      _amountController.clear();
      _noteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense added"), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e"), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22),
                decoration: const InputDecoration(labelText: "Amount (₹)"),
                validator: (v) =>
                    (v == null || double.tryParse(v) == null) ? "Enter a valid amount" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Category>(
                value: _selected,
                dropdownColor: AppTheme.surface,
                decoration: const InputDecoration(labelText: "Category"),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (c) => setState(() => _selected = c),
              ),
              const SizedBox(height: 16),
              ListTile(
                tileColor: AppTheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: Text("Date: ${_date.toLocal().toString().split(' ').first}"),
                trailing: const Icon(Icons.calendar_today, color: AppTheme.gold),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: "Note (optional)"),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Save Expense"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
