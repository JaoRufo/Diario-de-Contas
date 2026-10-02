import 'dart:io';

import 'package:diario_de_contas/models/expense.dart';
import 'package:diario_de_contas/services/pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gera um relatório PDF legível com resumo e lançamentos', () async {
    final month = DateTime(2026, 10);
    final bytes = await PdfService().buildReport(
      title: 'Despesas de Outubro 2026',
      months: [month],
      expenses: [
        Expense(
          id: '1',
          person: 'Pai',
          account: 'Banco do Brasil',
          amounts: [120.50, 80],
          month: month,
        ),
        Expense(
          id: '2',
          person: 'Mãe',
          account: 'Nubank',
          amounts: [45.90],
          month: month,
        ),
      ],
    );
    final file = File('tmp/pdfs/pdf-preview.pdf')..createSync(recursive: true);
    await file.writeAsBytes(bytes);
    expect(bytes.take(5), orderedEquals([37, 80, 68, 70, 45]));
  });
}
