import 'package:flutter/foundation.dart';
import 'package:diario_de_contas/models/expense.dart';
import 'package:diario_de_contas/services/storage_service.dart';

class ExpensesProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final List<Expense> _expenses = [];
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<Expense> get expenses => List.unmodifiable(_expenses);

  List<Expense> get currentExpenses => _expenses
      .where((expense) => expense.monthKey == monthKey(selectedMonth))
      .toList();

  double get monthTotal => currentExpenses.fold(
        0,
        (sum, expense) => sum + expense.total,
      );

  static String monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  Future<void> load() async {
    _expenses
      ..clear()
      ..addAll(await _storage.readExpenses());
    notifyListeners();
  }

  void setMonth(DateTime month) {
    selectedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  Future<void> save({
    String? id,
    required String person,
    required String account,
    required List<double> amounts,
  }) async {
    final item = Expense(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      person: person.trim(),
      account: account.trim(),
      amounts: amounts,
      month: selectedMonth,
    );
    final index = id == null ? -1 : _expenses.indexWhere((e) => e.id == id);
    if (index >= 0) {
      _expenses[index] = item;
    } else {
      _expenses.add(item);
    }
    await _storage.saveExpenses(_expenses);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _expenses.removeWhere((expense) => expense.id == id);
    await _storage.saveExpenses(_expenses);
    notifyListeners();
  }

  Map<String, List<Expense>> groupedByPerson() {
    final result = <String, List<Expense>>{};
    for (final expense in currentExpenses) {
      result.putIfAbsent(expense.person, () => []).add(expense);
    }
    return result;
  }

  Map<String, double> totalsByAccount() {
    final result = <String, double>{};
    for (final expense in currentExpenses) {
      result[expense.account] = (result[expense.account] ?? 0) + expense.total;
    }
    return result;
  }

  List<DateTime> previousMonths() {
    final currentKey = monthKey(selectedMonth);
    final months = <String, DateTime>{};
    for (final expense in _expenses) {
      if (expense.monthKey.compareTo(currentKey) < 0) {
        months[expense.monthKey] = expense.month;
      }
    }
    final result = months.values.toList()..sort((a, b) => b.compareTo(a));
    return result;
  }

  List<Expense> expensesForMonths(Iterable<DateTime> months) {
    final keys = months.map(monthKey).toSet();
    return _expenses
        .where((expense) => keys.contains(expense.monthKey))
        .toList();
  }
}
