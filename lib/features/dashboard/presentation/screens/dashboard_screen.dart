import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/exchange_rate_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../transactions/domain/entities/transaction_models.dart';
import '../../../transactions/presentation/controllers/quick_transaction_controller.dart';
import '../widgets/category_donut_chart.dart';

/// Pantalla principal (Dashboard) de Realito con:
/// - Disponible en Pesos (ARS) o Dólares (USD)
/// - Dólar Oficial (Precio de Venta)
/// - Filtro por Mes (Octubre, Septiembre, Agosto 2026)
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayCurrency = ref.watch(dashboardDisplayCurrencyProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final allTransactions = ref.watch(transactionsProvider);
    final allBills = ref.watch(monthlyBillsProvider);
    final categories = ref.watch(categoriesProvider);
    final accounts = ref.watch(accountsProvider);
    final liveRates = ref.watch(liveExchangeRatesProvider);

    final activeOficialRate = liveRates.rateFor(ExchangeRateType.oficial);

    final monthTransactions = allTransactions
        .where((t) => t.monthKey == selectedMonth.key)
        .toList();
    final monthBills =
        allBills.where((b) => b.monthKey == selectedMonth.key).toList();

    int toDisplay(int arsMinor) {
      if (displayCurrency == 'USD') {
        return MoneyFormatter.convertArsMinorToUsdMinor(
          arsAmountMinor: arsMinor,
          exchangeRateToUsd: activeOficialRate,
        );
      }
      return arsMinor;
    }

    final int incomeArsMinor = monthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold<int>(0, (s, t) => s + t.amountMinor);

    final int dailyExpensesArsMinor = monthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold<int>(0, (s, t) => s + t.amountMinor);

    final int fixedBillsTotalArsMinor =
        monthBills.fold<int>(0, (s, b) => s + b.amountMinor);

    final int fixedBillsPendingArsMinor =
        monthBills.fold<int>(0, (s, b) => s + b.pendingMinor);

    final int availableAfterAllArsMinor =
        incomeArsMinor - fixedBillsTotalArsMinor - dailyExpensesArsMinor;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_graph_rounded, color: AppColors.primaryLight),
            SizedBox(width: 8),
            Text('Realito'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: Text(
                displayCurrency == 'ARS' ? 'Pesos (ARS)' : 'Dólares (USD)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                ref.read(dashboardDisplayCurrencyProvider.notifier).state =
                    displayCurrency == 'ARS' ? 'USD' : 'ARS';
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          // 0. Selector de Mes (Octubre 2026 | Septiembre 2026 | Agosto 2026)
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
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      selected: period == selectedMonth,
                      onSelected: (_) {
                        ref.read(selectedMonthProvider.notifier).state = period;
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 1. Cinta de Dólar Oficial (Precio de Venta)
          _OficialRateTickerBar(
            sellRate: activeOficialRate,
            onRefresh: () =>
                ref.read(liveExchangeRatesProvider.notifier).refreshRates(),
          ),
          const SizedBox(height: 12),

          // 2. Tarjeta de Disponible en Pesos (ARS) o Dólares (USD)
          _MonthlyAvailableCard(
            monthLabel: selectedMonth.label,
            currencyCode: displayCurrency,
            availableMinor: toDisplay(availableAfterAllArsMinor),
            incomeMinor: toDisplay(incomeArsMinor),
            fixedBillsMinor: toDisplay(fixedBillsTotalArsMinor),
            dailyExpensesMinor: toDisplay(dailyExpensesArsMinor),
            oficialRateUsed: activeOficialRate,
          ),
          const SizedBox(height: 16),

          // 3. Acceso Rápido al Checklist de Gastos Fijos del Mes
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x1F0D7A5F),
                child: Icon(
                  Icons.checklist_rtl_rounded,
                  color: AppColors.primaryLight,
                ),
              ),
              title: Text(
                'Gastos Fijos — ${selectedMonth.label}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                fixedBillsPendingArsMinor > 0
                    ? 'Falta pagar: ${MoneyFormatter.formatMinor(toDisplay(fixedBillsPendingArsMinor), currencyCode: displayCurrency)}'
                    : '¡Todos los gastos fijos del mes están al día!',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/planning'),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Gráfico de Dona de Gastos por Categoría
          CategoryBreakdownCard(
            transactions: monthTransactions,
            categories: categories,
            displayCurrency: displayCurrency,
          ),
          const SizedBox(height: 18),

          // 5. Movimientos del Mes Seleccionado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gastos Diarios (${selectedMonth.label})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/quick-transaction'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Cargar'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final tx in monthTransactions.take(10))
            _TransactionListTile(
              tx: tx,
              categories: categories,
              accounts: accounts,
            ),
        ],
      ),
    );
  }
}

class _OficialRateTickerBar extends StatelessWidget {
  const _OficialRateTickerBar({
    required this.sellRate,
    required this.onRefresh,
  });

  final double sellRate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.currency_exchange_rounded,
            size: 16,
            color: AppColors.primaryLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dólar Oficial: \$${sellRate.toStringAsFixed(0)} ARS',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          InkWell(
            onTap: onRefresh,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.refresh_rounded, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyAvailableCard extends StatelessWidget {
  const _MonthlyAvailableCard({
    required this.monthLabel,
    required this.currencyCode,
    required this.availableMinor,
    required this.incomeMinor,
    required this.fixedBillsMinor,
    required this.dailyExpensesMinor,
    required this.oficialRateUsed,
  });

  final String monthLabel;
  final String currencyCode;
  final int availableMinor;
  final int incomeMinor;
  final int fixedBillsMinor;
  final int dailyExpensesMinor;
  final double oficialRateUsed;

  @override
  Widget build(BuildContext context) {
    final isNegative = availableMinor < 0;
    final titleText = currencyCode == 'ARS'
        ? 'Disponible en Pesos (ARS) — $monthLabel'
        : 'Disponible en Dólares (USD) — $monthLabel';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNegative
              ? const [Color(0xFF9F1239), Color(0xFF4C0519)]
              : const [Color(0xFF0D7A5F), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            MoneyFormatter.formatMinor(
              availableMinor,
              currencyCode: currencyCode,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isNegative
                ? '⚠️ En este mes los gastos fijos + diarios superaron el ingreso'
                : 'Saldo libre en $currencyCode descontando Gastos Fijos y Diarios',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  label: 'Sueldo + Adelanto',
                  value: MoneyFormatter.formatMinor(
                    incomeMinor,
                    currencyCode: currencyCode,
                  ),
                  valueColor: const Color(0xFF4ADE80),
                ),
              ),
              Expanded(
                child: _MetricColumn(
                  label: 'Gastos Fijos Mes',
                  value: MoneyFormatter.formatMinor(
                    fixedBillsMinor,
                    currencyCode: currencyCode,
                  ),
                  valueColor: const Color(0xFFFBBF24),
                ),
              ),
              Expanded(
                child: _MetricColumn(
                  label: 'Gastos Diarios',
                  value: MoneyFormatter.formatMinor(
                    dailyExpensesMinor,
                    currencyCode: currencyCode,
                  ),
                  valueColor: const Color(0xFFFB7185),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _TransactionListTile extends StatelessWidget {
  const _TransactionListTile({
    required this.tx,
    required this.categories,
    required this.accounts,
  });

  final TransactionEntity tx;
  final List<CategoryEntity> categories;
  final List<AccountEntity> accounts;

  @override
  Widget build(BuildContext context) {
    final category =
        categories.where((c) => c.id == tx.categoryId).firstOrNull;
    final account = accounts.firstWhere(
      (a) => a.id == tx.accountId,
      orElse: () => accounts.first,
    );

    final isExpense = tx.type == TransactionType.expense;
    final isTransfer = tx.type == TransactionType.transfer;

    final Color amountColor = isTransfer
        ? AppColors.transferLight
        : isExpense
            ? AppColors.expenseLight
            : AppColors.incomeLight;

    final String prefix = isTransfer
        ? '⇄ '
        : isExpense
            ? '- '
            : '+ ';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (category?.color ?? AppColors.transferLight)
              .withValues(alpha: 0.14),
          child: Icon(
            isTransfer
                ? Icons.swap_horiz_rounded
                : (category?.icon ?? Icons.receipt_long_rounded),
            color: category?.color ?? AppColors.transferLight,
          ),
        ),
        title: Text(
          tx.note.isNotEmpty ? tx.note : (category?.name ?? 'Movimiento'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${tx.dayLabel} • ${category?.name ?? ''} (${account.name})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$prefix${MoneyFormatter.formatMinor(tx.amountMinor, currencyCode: tx.currencyCode)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: amountColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'US\$ ${(tx.amountUsdMinor / 100).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
