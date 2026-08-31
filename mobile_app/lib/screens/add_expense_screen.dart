import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/expense.dart';
import '../theme.dart';

/// Used for both adding a new expense and editing an existing one.
/// Pass [existing] to pre-fill the form and switch it into edit mode.
class AddExpenseScreen extends StatefulWidget {
  final Expense? existing;

  const AddExpenseScreen({super.key, this.existing});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  List<Category> _categories = [];
  Category? _selected;
  late DateTime _date;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amountController = TextEditingController(text: e != null ? e.amount.toString() : "");
    _noteController = TextEditingController(text: e?.note ?? "");
    _date = e?.expenseDate ?? DateTime.now();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _api.getCategories();
    setState(() {
      _categories = cats;
      final existingCategoryId = widget.existing?.category.id;
      _selected = existingCategoryId != null
          ? cats.firstWhere((c) => c.id == existingCategoryId, orElse: () => cats.first)
          : (cats.isNotEmpty ? cats.first : null);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selected == null) return;
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await _api.updateExpense(
          id: widget.existing!.id,
          categoryId: _selected!.id,
          amount: double.parse(_amountController.text),
          date: _date,
          note: _noteController.text.isEmpty ? null : _noteController.text,
        );
      } else {
        await _api.createExpense(
          categoryId: _selected!.id,
          amount: double.parse(_amountController.text),
          date: _date,
          note: _noteController.text.isEmpty ? null : _noteController.text,
        );
        _amountController.clear();
        _noteController.clear();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? "Expense updated" : "Expense added"),
            backgroundColor: AppTheme.success,
          ),
        );
        if (_isEditing) {
          Navigator.of(context).pop(true); // signal the caller to refresh
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e"), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? "Edit Expense" : "Add Expense")),
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
                decoration: const InputDecoration(labelText: "Category"),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                    .toList(),
                onChanged: (c) => setState(() => _selected = c),
              ),
              const SizedBox(height: 16),
              ListTile(
                tileColor: const Color(0xFFF5F1E6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: Text("Date: ${_date.toLocal().toString().split(' ').first}"),
                trailing: const Icon(Icons.calendar_today, color: AppTheme.emerald),
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
                    : Text(_isEditing ? "Save Changes" : "Save Expense"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
