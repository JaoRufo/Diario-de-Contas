import 'package:flutter/material.dart';
import 'package:diario_de_contas/models/expense.dart';
import 'package:diario_de_contas/providers/expenses_provider.dart';
import 'package:diario_de_contas/utils/formatters.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, required this.provider, this.expense});
  final ExpensesProvider provider;
  final Expense? expense;
  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  late final TextEditingController personController,
      accountController,
      amountsController;
  final formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    final item = widget.expense;
    personController = TextEditingController(text: item?.person);
    accountController = TextEditingController(text: item?.account);
    amountsController = TextEditingController(
      text: item?.amounts
          .map((e) => e.toStringAsFixed(2).replaceAll('.', ','))
          .join(', '),
    );
  }

  @override
  void dispose() {
    personController.dispose();
    accountController.dispose();
    amountsController.dispose();
    super.dispose();
  }

  List<double> parseAmounts(String raw) {
    final result = <double>[];
    for (final chunk
        in raw
            .replaceAll(';', ' ')
            .replaceAll('/', ' ')
            .split(RegExp(r'\s+'))) {
      if (chunk.isEmpty) {
        continue;
      }
      final commas = ','.allMatches(chunk).length;
      final pieces = commas > 1 ? chunk.split(',') : [chunk];
      for (final piece in pieces) {
        final normalized = piece.replaceAll('.', '').replaceAll(',', '.');
        final value = double.tryParse(normalized);
        if (value != null && value > 0) result.add(value);
      }
    }
    return result;
  }

  Future<void> submit() async {
    final amounts = parseAmounts(amountsController.text);
    if (!formKey.currentState!.validate() || amounts.isEmpty) {
      if (amounts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe pelo menos um valor válido.')),
        );
      }
      return;
    }
    await widget.provider.save(
      id: widget.expense?.id,
      person: personController.text,
      account: accountController.text,
      amounts: amounts,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.expense == null ? 'Novo lançamento' : 'Editar lançamento',
      ),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text('Competência', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF7),
              border: Border.all(color: const Color(0xFFE5DED1)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined,
                    color: Color(0xFFB88632)),
                const SizedBox(width: 12),
                Text(
                  monthLabel(widget.provider.selectedMonth),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: personController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Pessoa',
              hintText: 'Ex.: Pai, Mãe, João',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Informe a pessoa' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: accountController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Banco ou cartão',
              hintText: 'Ex.: Itaú, Nubank, Carrefour',
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Informe o banco ou cartão'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: amountsController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valores',
              hintText: 'Ex.: 35,90 120,50 / 80',
              helperText: 'Separe por vírgula, espaço ou barra.',
            ),
            validator: (v) => v == null || parseAmounts(v).isEmpty
                ? 'Informe valores válidos'
                : null,
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: submit,
            icon: const Icon(Icons.check),
            label: const Padding(
              padding: EdgeInsets.all(4),
              child: Text('Salvar lançamento'),
            ),
          ),
        ],
      ),
    ),
  );
}
