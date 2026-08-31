import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense.dart';

class ApiService {
  static const String baseUrl = "https://expense-tracker-8uwu.onrender.com";

  Future<List<Category>> getCategories() async {
    final res = await http.get(Uri.parse("$baseUrl/categories"));
    _check(res);
    final List data = jsonDecode(res.body);
    return data.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<Expense>> getExpenses({DateTime? start, DateTime? end}) async {
    final qp = <String, String>{};
    if (start != null) qp['start'] = start.toIso8601String().split('T').first;
    if (end != null) qp['end'] = end.toIso8601String().split('T').first;
    final uri = Uri.parse("$baseUrl/expenses").replace(queryParameters: qp);
    final res = await http.get(uri);
    _check(res);
    final List data = jsonDecode(res.body);
    return data.map((e) => Expense.fromJson(e)).toList();
  }

  Future<Expense> createExpense({
    required String categoryId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/expenses"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "category_id": categoryId,
        "amount": amount,
        "note": note,
        "expense_date": date.toIso8601String().split('T').first,
      }),
    );
    _check(res);
    return Expense.fromJson(jsonDecode(res.body));
  }

  Future<void> deleteExpense(String id) async {
    final res = await http.delete(Uri.parse("$baseUrl/expenses/$id"));
    _check(res);
  }

  Future<DashboardResponse> getDashboard(String period, {DateTime? start, DateTime? end}) async {
    final qp = <String, String>{};
    if (start != null) qp['start'] = start.toIso8601String().split('T').first;
    if (end != null) qp['end'] = end.toIso8601String().split('T').first;
    final uri = Uri.parse("$baseUrl/dashboard/$period").replace(queryParameters: qp);
    final res = await http.get(uri);
    _check(res);
    return DashboardResponse.fromJson(jsonDecode(res.body));
  }

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      throw Exception("API error ${res.statusCode}: ${res.body}");
    }
  }
}
