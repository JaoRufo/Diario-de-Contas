import 'dart:typed_data';

import 'package:diario_de_contas/models/expense.dart';
import 'package:diario_de_contas/utils/formatters.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static const _ink = PdfColor.fromInt(0xFF17130D);
  static const _gold = PdfColor.fromInt(0xFFB88632);
  static const _cream = PdfColor.fromInt(0xFFFFFCF7);
  static const _muted = PdfColor.fromInt(0xFF80786B);
  static const _line = PdfColor.fromInt(0xFFE5DED1);

  Future<void> shareReport({
    required String title,
    required List<Expense> expenses,
    required List<DateTime> months,
    String? person,
  }) async {
    if (expenses.isEmpty) return;
    final bytes = await buildReport(
      title: title,
      expenses: expenses,
      months: months,
      person: person,
    );
    final filename = _filename(title);
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<Uint8List> buildReport({
    required String title,
    required List<Expense> expenses,
    required List<DateTime> months,
    String? person,
  }) {
    return _buildPdf(
      title: title,
      expenses: expenses,
      months: months,
      person: person,
    );
  }

  Future<Uint8List> _buildPdf({
    required String title,
    required List<Expense> expenses,
    required List<DateTime> months,
    String? person,
  }) async {
    final document = pw.Document();
    final grouped = <String, List<Expense>>{};
    for (final expense in expenses) {
      grouped.putIfAbsent(expense.person, () => []).add(expense);
    }
    final total = expenses.fold<double>(0, (sum, item) => sum + item.total);
    final period = months.map(monthLabel).join('  |  ');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 34, 34, 38),
        header: (context) => _header(context, title, period),
        footer: (context) => _footer(context),
        build: (context) => [
          pw.SizedBox(height: 18),
          _summary(total: total, count: expenses.length, period: period),
          pw.SizedBox(height: 24),
          ...grouped.entries.expand(
            (entry) => [
              _personSection(entry.key, entry.value),
              pw.SizedBox(height: 18),
            ],
          ),
          pw.Divider(color: _line, thickness: 1),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('TOTAL GERAL', style: _labelStyle()),
              pw.SizedBox(width: 18),
              pw.Text(_money(total), style: _totalStyle()),
            ],
          ),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _header(pw.Context context, String title, String period) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('DIARIO DE CONTAS',
                style: pw.TextStyle(
                    color: _gold,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.2)),
            pw.Text('Relatório financeiro',
                style: pw.TextStyle(color: _muted, fontSize: 9)),
          ],
        ),
        pw.SizedBox(height: 13),
        pw.Text(title,
            style: pw.TextStyle(
                color: _ink, fontSize: 23, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(period, style: pw.TextStyle(color: _muted, fontSize: 10)),
        pw.SizedBox(height: 10),
        pw.Container(height: 2, color: _gold),
      ],
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Gerado pelo Diário de Contas',
            style: pw.TextStyle(color: _muted, fontSize: 8)),
        pw.Text('Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(color: _muted, fontSize: 8)),
      ],
    );
  }

  pw.Widget _summary(
      {required double total, required int count, required String period}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
          color: _cream,
          border: pw.Border.all(color: _line),
          borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('TOTAL DO PERÍODO', style: _labelStyle()),
            pw.SizedBox(height: 5),
            pw.Text(_money(total), style: _totalStyle()),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('$count ${count == 1 ? 'lançamento' : 'lançamentos'}',
                style: pw.TextStyle(
                    color: _ink, fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(period, style: pw.TextStyle(color: _muted, fontSize: 9)),
          ]),
        ],
      ),
    );
  }

  pw.Widget _personSection(String person, List<Expense> expenses) {
    final total = expenses.fold<double>(0, (sum, item) => sum + item.total);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(person,
              style: pw.TextStyle(
                  color: _ink, fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Text(_money(total),
              style: pw.TextStyle(
                  color: _gold, fontSize: 13, fontWeight: pw.FontWeight.bold)),
        ]),
        pw.SizedBox(height: 9),
        pw.Table(
          border: pw.TableBorder.all(color: _line, width: .6),
          columnWidths: const {
            0: pw.FlexColumnWidth(2.2),
            1: pw.FlexColumnWidth(3.4),
            2: pw.FlexColumnWidth(1.6)
          },
          children: [
            _tableRow(['Banco / cartão', 'Valores', 'Total'], header: true),
            ...expenses.map((expense) => _tableRow([
                  expense.account,
                  expense.amounts.map(_money).join('  |  '),
                  _money(expense.total),
                ])),
          ],
        ),
      ],
    );
  }

  pw.TableRow _tableRow(List<String> values, {bool header = false}) {
    return pw.TableRow(
      decoration: header ? const pw.BoxDecoration(color: _ink) : null,
      children: values
          .map((value) => pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: pw.Text(value,
                    style: pw.TextStyle(
                        color: header ? PdfColors.white : _ink,
                        fontSize: 9,
                        fontWeight: header
                            ? pw.FontWeight.bold
                            : pw.FontWeight.normal)),
              ))
          .toList(),
    );
  }

  pw.TextStyle _labelStyle() => pw.TextStyle(
      color: _muted,
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      letterSpacing: .6);
  pw.TextStyle _totalStyle() =>
      pw.TextStyle(color: _ink, fontSize: 20, fontWeight: pw.FontWeight.bold);
  String _money(double value) => money(value);
  String _filename(String title) =>
      '${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}.pdf';
}
