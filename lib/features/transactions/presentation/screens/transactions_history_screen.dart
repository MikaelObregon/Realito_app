import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/transaction_models.dart';
import '../controllers/quick_transaction_controller.dart';

/// Pestaña 2: Historial de Gastos Diarios e Ingresos con filtro por Mes
/// (Octubre 2026, Septiembre 2026, Agosto 2026), búsqueda por nota y exportación CSV.
class TransactionsHistoryScreen extends ConsumerStatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  ConsumerState<TransactionsHistoryScreen> createState() =>
      _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState
    extends ConsumerState<TransactionsHistoryScreen> {
  String _searchQuery = '';
  TransactionType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final allTransactions = ref.watch(transactionsProvider);
    final accounts = ref.watch(accountsProvider);
    final categories = ref.watch(categoriesProvider);

    final filtered = allTransactions.where((tx) {
      if (tx.monthKey != selectedMonth.key) return false;
      if (_selectedType != null && tx.type != _selectedType) return false;
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final cat = categories.where((c) => c.id == tx.categoryId).firstOrNull;
        final acc = accounts.where((a) => a.id == tx.accountId).firstOrNull;
        final hay =
            '${tx.dayLabel} ${tx.note} ${cat?.name ?? ''} ${acc?.name ?? ''}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Diarios por Mes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('CSV'),
              onPressed: () {
                final csv = ref.read(transactionsProvider.notifier).exportToCsv(
                      filtered,
                      accounts,
                      categories,
                    );
                Clipboard.setData(ClipboardData(text: csv));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'CSV de ${selectedMonth.label} (${filtered.length} ítems) copiado',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Column(
              children: [
                // Selector de Mes
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final period in MonthPeriod.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              period.label,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            selected: period == selectedMonth,
                            onSelected: (_) {
                              ref.read(selectedMonthProvider.notifier).state =
                                  period;
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText:
                        'Buscar día o nota (ej. Martes 06, Emilis, Carrefour, Uber)...',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Todos'),
                        selected: _selectedType == null,
                        onSelected: (_) => setState(() => _selectedType = null),
                      ),
                      const SizedBox(width: 8),
                      for (final type in TransactionType.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text('${type.label}s'),
                            selected: _selectedType == type,
                            onSelected: (_) => setState(
                              () => _selectedType =
                                  _selectedType == type ? null : type,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No hay movimientos para este filtro.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      final cat = categories
                          .where((c) => c.id == tx.categoryId)
                          .firstOrNull;
                      final acc = accounts.firstWhere(
                        (a) => a.id == tx.accountId,
                        orElse: () => accounts.first,
                      );

                      final isExpense = tx.type == TransactionType.expense;
                      final isTransfer = tx.type == TransactionType.transfer;
                      final color = isTransfer
                          ? AppColors.transferLight
                          : isExpense
                              ? AppColors.expenseLight
                              : AppColors.incomeLight;
                      final prefix = isTransfer
                          ? '⇄ '
                          : isExpense
                              ? '- '
                              : '+ ';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                (cat?.color ?? AppColors.transferLight)
                                    .withValues(alpha: 0.15),
                            child: Icon(
                              isTransfer
                                  ? Icons.swap_horiz_rounded
                                  : (cat?.icon ?? Icons.receipt_long_rounded),
                              color: cat?.color ?? AppColors.transferLight,
                            ),
                          ),
                          title: Text(
                            tx.note.isNotEmpty
                                ? tx.note
                                : (cat?.name ?? 'Movimiento'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '📅 ${tx.dayLabel} • ${cat?.name ?? ''} (${acc.name})',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$prefix${MoneyFormatter.formatMinor(tx.amountMinor, currencyCode: tx.currencyCode)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'US\$ ${(tx.amountUsdMinor / 100).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
