import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diario_de_contas/models/expense.dart';

class StorageService {
  static const _key = 'diario_de_contas_expenses';
  Future<List<Expense>> readExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final data = jsonDecode(raw) as List;
    return data
        .map((item) => Expense.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(expenses.map((e) => e.toJson()).toList()));
  }
}
