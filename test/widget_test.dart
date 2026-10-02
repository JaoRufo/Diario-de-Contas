import 'package:flutter_test/flutter_test.dart';
import 'package:diario_de_contas/main.dart';
import 'package:diario_de_contas/providers/expenses_provider.dart';

void main() {
  testWidgets('exibe a tela inicial do Diário de Contas', (tester) async {
    await tester.pumpWidget(DiarioDeContasApp(provider: ExpensesProvider()));
    expect(find.text('Diário de Contas'), findsOneWidget);
    expect(find.text('Nenhum lançamento neste mês'), findsOneWidget);
  });
}
