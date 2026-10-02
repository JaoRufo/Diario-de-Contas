class Expense {
  const Expense(
      {required this.id,
      required this.person,
      required this.account,
      required this.amounts,
      required this.month});
  final String id;
  final String person;
  final String account;
  final List<double> amounts;
  final DateTime month;
  double get total => amounts.fold(0, (sum, value) => sum + value);
  String get monthKey =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';
  Map<String, dynamic> toJson() => {
        'id': id,
        'person': person,
        'account': account,
        'amounts': amounts,
        'month': monthKey
      };
  factory Expense.fromJson(Map<String, dynamic> json) {
    final parts = (json['month'] as String).split('-');
    return Expense(
        id: json['id'] as String,
        person: json['person'] as String,
        account: json['account'] as String,
        amounts: (json['amounts'] as List)
            .map((e) => (e as num).toDouble())
            .toList(),
        month: DateTime(int.parse(parts[0]), int.parse(parts[1])));
  }
}
