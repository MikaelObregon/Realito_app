import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/exchange_rate_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../transactions/domain/entities/transaction_models.dart';
import '../../../transactions/presentation/controllers/quick_transaction_controller.dart';

/// Pestaña 4: Gestión de Cuentas/Billeteras (ARS y USD), Patrimonio Neto Consolidado
/// y Reglas de Transacciones Recurrentes (Alquiler, Sueldo, Suscripciones en USD).
class AccountsManagementScreen extends ConsumerWidget {
  const AccountsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final recurringRules = ref.watch(recurringRulesProvider);
    final liveRates = ref.watch(liveExchangeRatesProvider);

    final mepRate = liveRates.rateFor(ExchangeRateType.mep);

    // Cálculo de Patrimonio Neto Consolidado en USD (Moneda Dura) y ARS
    int totalArsEquivalentMinor = 0;
    int totalUsdEquivalentMinor = 0;

    for (final acc in accounts) {
      if (acc.currencyCode == 'USD') {
        totalUsdEquivalentMinor += acc.balanceMinor;
        totalArsEquivalentMinor += MoneyFormatter.convertUsdMinorToArsMinor(
          usdAmountMinor: acc.balanceMinor,
          exchangeRateToUsd: mepRate,
        );
      } else {
        totalArsEquivalentMinor += acc.balanceMinor;
        totalUsdEquivalentMinor += MoneyFormatter.convertArsMinorToUsdMinor(
          arsAmountMinor: acc.balanceMinor,
          exchangeRateToUsd: mepRate,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas y Recurrentes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nueva Cuenta'),
              onPressed: () => _showAddAccountDialog(context, ref),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // 1. Resumen de Patrimonio Neto Consolidado
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patrimonio Consolidado (Bimonetario)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    MoneyFormatter.formatMinor(
                      totalUsdEquivalentMinor,
                      currencyCode: 'USD',
                    ),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  Text(
                    'Equivalente en Pesos (MEP \$${mepRate.toStringAsFixed(0)}): ${MoneyFormatter.formatMinor(totalArsEquivalentMinor, currencyCode: 'ARS')}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. Listado de Billeteras y Cuentas
          const Text(
            'Mis Billeteras y Cuentas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final acc in accounts)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: acc.color.withValues(alpha: 0.15),
                  child: Icon(acc.icon, color: acc.color),
                ),
                title: Text(
                  acc.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${acc.accountTypeLabel} • ${acc.currencyCode}'),
                trailing: Text(
                  MoneyFormatter.formatMinor(
                    acc.balanceMinor,
                    currencyCode: acc.currencyCode,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 22),

          // 3. Transacciones Recurrentes (Sueldo, Alquiler, Suscripciones en USD)
          const Text(
            'Transacciones Recurrentes Programadas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ejecutá vencimientos con 1 toque o programalos automáticamente.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),

          for (final rule in recurringRules)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: rule.type == TransactionType.income
                      ? AppColors.incomeLight.withValues(alpha: 0.15)
                      : AppColors.expenseLight.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.event_repeat_rounded,
                    color: rule.type == TransactionType.income
                        ? AppColors.incomeLight
                        : AppColors.expenseLight,
                  ),
                ),
                title: Text(
                  rule.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Día ${rule.dayOfMonth} de cada mes • ${rule.rateType.label}',
                ),
                trailing: FilledButton.tonal(
                  onPressed: () {
                    final rate = liveRates.rateFor(rule.rateType);
                    final isUsdRule = rule.currencyCode == 'USD';
                    final originAcc = accounts.firstWhere(
                      (a) => a.id == rule.accountId,
                      orElse: () => accounts.first,
                    );

                    final int debitedMinor;
                    final int usdMinor;
                    if (isUsdRule && originAcc.currencyCode == 'ARS') {
                      // Ej: Netflix US$ 15.99 debitado en ARS al Dólar Tarjeta
                      usdMinor = rule.amountMinor;
                      debitedMinor = MoneyFormatter.convertUsdMinorToArsMinor(
                        usdAmountMinor: rule.amountMinor,
                        exchangeRateToUsd: rate,
                      );
                    } else if (!isUsdRule) {
                      debitedMinor = rule.amountMinor;
                      usdMinor = MoneyFormatter.convertArsMinorToUsdMinor(
                        arsAmountMinor: rule.amountMinor,
                        exchangeRateToUsd: rate,
                      );
                    } else {
                      debitedMinor = rule.amountMinor;
                      usdMinor = rule.amountMinor;
                    }

                    final tx = TransactionEntity(
                      id: 'tx_rec_${DateTime.now().microsecondsSinceEpoch}',
                      type: rule.type,
                      accountId: originAcc.id,
                      categoryId: rule.categoryId,
                      amountMinor: debitedMinor,
                      currencyCode: originAcc.currencyCode,
                      exchangeRateType: rule.rateType,
                      exchangeRateToUsd: rate,
                      amountUsdMinor: usdMinor,
                      transactionDate: DateTime.now(),
                      note: '${rule.title} (Recurrente)',
                    );

                    ref.read(transactionsProvider.notifier).addTransaction(tx);
                    ref.read(accountsProvider.notifier).applyTransaction(tx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Registrado: ${rule.title}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(
                    MoneyFormatter.formatMinor(
                      rule.amountMinor,
                      currencyCode: rule.currencyCode,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    String currency = 'ARS';
    String typeLabel = 'Billetera Virtual';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Crear Nueva Cuenta / Billetera'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre (ej. Brubank, Lemon, Santander)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saldo inicial',
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ARS', label: Text('Pesos (ARS)')),
                  ButtonSegment(value: 'USD', label: Text('Dólares (USD)')),
                ],
                selected: {currency},
                onSelectionChanged: (s) =>
                    setDialogState(() => currency = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final initial = int.tryParse(balanceCtrl.text.trim()) ?? 0;
                if (nameCtrl.text.trim().isNotEmpty) {
                  ref.read(accountsProvider.notifier).addAccount(
                        name: nameCtrl.text.trim(),
                        currencyCode: currency,
                        initialBalanceMinor: initial * 100,
                        accountTypeLabel: typeLabel,
                      );
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Guardar Cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}

