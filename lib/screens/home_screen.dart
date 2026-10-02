import 'package:flutter/material.dart';
import 'package:diario_de_contas/models/expense.dart';
import 'package:diario_de_contas/providers/expenses_provider.dart';
import 'package:diario_de_contas/screens/expense_form_screen.dart';
import 'package:diario_de_contas/utils/formatters.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.provider});

  final ExpensesProvider provider;

  Future<void> _pickMonth(BuildContext context) async {
    final result = await showDatePicker(
      context: context,
      initialDate: provider.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Selecione a competência',
    );
    if (result != null) provider.setMonth(result);
  }

  Future<void> _openForm(BuildContext context, [Expense? expense]) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseFormScreen(provider: provider, expense: expense),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final groups = provider.groupedByPerson();
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Diário de Contas',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                onPressed: () => _pickMonth(context),
                icon: const Icon(Icons.calendar_today_outlined),
                tooltip: 'Escolher mês',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Lançar'),
          ),
          body: RefreshIndicator(
            onRefresh: provider.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              children: [
                _MonthSelector(
                  provider: provider,
                  onTap: () => _pickMonth(context),
                ),
                const SizedBox(height: 16),
                _TotalCard(
                  total: provider.monthTotal,
                  count: provider.currentExpenses.length,
                ),
                const SizedBox(height: 28),
                if (groups.isEmpty)
                  _EmptyState(onAdd: () => _openForm(context))
                else ...[
                  Text(
                    'Por pessoa',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ...groups.entries.map(
                    (entry) => _PersonCard(
                      person: entry.key,
                      expenses: entry.value,
                      onEdit: (expense) => _openForm(context, expense),
                      onDelete: (expense) => _confirmDelete(context, expense),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SummaryCard(totals: provider.totalsByAccount()),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Expense item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: Text('${item.person} • ${item.account}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.remove(item.id);
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.provider, required this.onTap});

  final ExpensesProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final month = provider.selectedMonth;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () =>
              provider.setMonth(DateTime(month.year, month.month - 1)),
          icon: const Icon(Icons.chevron_left),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  monthLabel(month),
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () =>
              provider.setMonth(DateTime(month.year, month.month + 1)),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.count});

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1E2C3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total do mês',
                    style: TextStyle(color: Color(0xFF80786B))),
                const SizedBox(height: 4),
                Text(money(total),
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.w800)),
                Text('$count ${count == 1 ? 'lançamento' : 'lançamentos'}',
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard(
      {required this.person,
      required this.expenses,
      required this.onEdit,
      required this.onDelete});

  final String person;
  final List<Expense> expenses;
  final ValueChanged<Expense> onEdit;
  final ValueChanged<Expense> onDelete;

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold(0.0, (sum, expense) => sum + expense.total);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFF1E2C3),
                  child: Text(person.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF8A641F),
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(person,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700))),
                Text(money(total),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const Divider(height: 24),
            ...expenses.map((expense) => _ExpenseRow(
                expense: expense, onEdit: onEdit, onDelete: onDelete)),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow(
      {required this.expense, required this.onEdit, required this.onDelete});

  final Expense expense;
  final ValueChanged<Expense> onEdit;
  final ValueChanged<Expense> onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.credit_card_outlined,
              size: 20, color: Color(0xFFB88632)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.account,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                Text(expense.amounts.map(money).join('  •  '),
                    style: const TextStyle(
                        color: Color(0xFF80786B), fontSize: 12)),
              ],
            ),
          ),
          Text(money(expense.total),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            iconSize: 20,
            onSelected: (value) =>
                value == 'edit' ? onEdit(expense) : onDelete(expense),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totals});

  final Map<String, double> totals;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Totais fatura dos cartões',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            const Text('Consolidado de todas as pessoas',
                style: TextStyle(color: Color(0xFF80786B))),
            const SizedBox(height: 16),
            ...totals.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Expanded(child: Text(entry.key)),
                    Text(money(entry.value),
                        style: const TextStyle(fontWeight: FontWeight.w700))
                  ]),
                )),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 48, color: Color(0xFFB88632)),
            const SizedBox(height: 12),
            const Text('Nenhum lançamento neste mês',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Comece registrando uma despesa.',
                style: TextStyle(color: Color(0xFF80786B))),
            const SizedBox(height: 18),
            OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar lançamento')),
          ],
        ),
      ),
    );
  }
}
