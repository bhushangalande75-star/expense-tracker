class Category {
  final String id;
  final String name;
  final String icon;
  final String colorHex;

  Category({required this.id, required this.name, required this.icon, required this.colorHex});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        icon: json['icon'],
        colorHex: json['color_hex'],
      );
}

class Expense {
  final String id;
  final Category category;
  final double amount;
  final String? note;
  final DateTime expenseDate;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.note,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        category: Category.fromJson(json['category']),
        amount: (json['amount'] as num).toDouble(),
        expenseDate: DateTime.parse(json['expense_date']),
        note: json['note'],
      );
}

class DashboardBucket {
  final String label;
  final double total;
  final Map<String, double> byCategory;

  DashboardBucket({required this.label, required this.total, required this.byCategory});

  factory DashboardBucket.fromJson(Map<String, dynamic> json) => DashboardBucket(
        label: json['label'],
        total: (json['total'] as num).toDouble(),
        byCategory: (json['by_category'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
}

class DashboardResponse {
  final String period;
  final List<DashboardBucket> buckets;
  final double grandTotal;

  DashboardResponse({required this.period, required this.buckets, required this.grandTotal});

  factory DashboardResponse.fromJson(Map<String, dynamic> json) => DashboardResponse(
        period: json['period'],
        buckets: (json['buckets'] as List).map((b) => DashboardBucket.fromJson(b)).toList(),
        grandTotal: (json['grand_total'] as num).toDouble(),
      );
}
