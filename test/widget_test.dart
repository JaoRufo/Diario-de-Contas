import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diario_de_contas/main.dart';
import 'package:diario_de_contas/providers/expenses_provider.dart';

void main() {
  testWidgets('exibe a tela inicial do Diario de Contas', (tester) async {
    await tester.pumpWidget(DiarioDeContasApp(provider: ExpensesProvider()));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
  });
}
