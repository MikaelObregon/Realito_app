import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/transaction_models.dart';
import '../controllers/quick_transaction_controller.dart';

/// Pantalla de Alta Rápida de Transacciones en <= 3 toques con:
/// - Tecla '+' de Suma Rápida (ej: '6100 + 7700' = $ 13.800 guardando el desglose en la nota)
/// - Tecla '000' para miles de pesos
/// - Campo de Nota para detallar en qué se gastó (ej: '8 cartera + 29 aros')
class QuickTransactionScreen extends ConsumerWidget {
  const QuickTransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quickTransactionControllerProvider);
    final controller = ref.read(quickTransactionControllerProvider.notifier);
    final accounts = ref.watch(accountsProvider);
    final allCategories = ref.watch(categoriesProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    final originAccount = accounts.firstWhere(
      (a) => a.id == state.selectedAccountId,
      orElse: () => accounts.first,
    );
    final filteredCategories =
        allCategories.where((c) => c.kind == state.type).toList();

    final usdEquivalentMinor =
        state.calculateUsdMinor(originAccount.currencyCode);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color accentColor;
    switch (state.type) {
      case TransactionType.expense:
        accentColor = isDark ? AppColors.expenseDark : AppColors.expenseLight;
      case TransactionType.income:
        accentColor = isDark ? AppColors.incomeDark : AppColors.incomeLight;
      case TransactionType.transfer:
        accentColor = isDark ? AppColors.transferDark : AppColors.transferLight;
    }

    void handleSave() {
      if (state.amountMinor <= 0) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingresá un monto mayor a cero'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      HapticFeedback.mediumImpact();
      final saved = controller.submitTransaction();
      if (saved && context.mounted) {
        context.pop();
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cerrar',
          onPressed: () => context.pop(),
        ),
        title: _TransactionTypeSelector(
          selected: state.type,
          onChanged: (type) {
            HapticFeedback.selectionClick();
            controller.setTransactionType(type);
          },
        ),
        centerTitle: true,
        actions: [
          Tooltip(
            message:
                'Modo 2 toques: guarda automáticamente al tocar una categoría',
            child: IconButton(
              icon: Icon(
                state.autoSaveOnCategoryTap
                    ? Icons.bolt_rounded
                    : Icons.bolt_outlined,
                color: state.autoSaveOnCategoryTap
                    ? AppColors.warningLight
                    : null,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                controller.toggleAutoSaveOnCategoryTap(
                  !state.autoSaveOnCategoryTap,
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Píldoras de Mes, Cuenta Origen/Destino y Cotización
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: Text(
                      selectedMonth.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _AccountSelectorChip(
                    labelPrefix:
                        state.type == TransactionType.transfer ? 'De: ' : '',
                    account: originAccount,
                    accounts: accounts,
                    onSelected: controller.selectAccount,
                  ),
                  if (state.type == TransactionType.transfer)
                    _AccountSelectorChip(
                      labelPrefix: 'A: ',
                      account: accounts.firstWhere(
                        (a) => a.id == state.toAccountId,
                        orElse: () => accounts.last,
                      ),
                      accounts: accounts
                          .where((a) => a.id != originAccount.id)
                          .toList(),
                      onSelected: controller.selectDestinationAccount,
                    ),
                  _ExchangeRateChip(
                    rateType: state.rateType,
                    rateValue: state.customExchangeRate,
                    onSelected: controller.selectExchangeRateType,
                  ),
                ],
              ),
            ),

            // 2. Visor de Monto Principal + Expresión de Suma ('6100 + 7700') + Nota
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.hasMultiSum)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Suma: ${state.rawExpression.replaceAll('+', ' + ')} =',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    Semantics(
                      label: 'Monto a registrar',
                      liveRegion: true,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          MoneyFormatter.formatMinor(
                            state.amountMinor,
                            currencyCode: originAccount.currencyCode,
                          ),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontSize: 46,
                                color: state.amountMinor == 0
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.35)
                                    : accentColor,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.usdBadgeBgDark
                            : AppColors.usdBadgeBgLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        originAccount.currencyCode == 'ARS'
                            ? '≈ ${MoneyFormatter.formatMinor(usdEquivalentMinor, currencyCode: 'USD')} (${state.rateType.label}: \$${state.customExchangeRate.toStringAsFixed(0)})'
                            : '≈ ${MoneyFormatter.formatMinor(MoneyFormatter.convertUsdMinorToArsMinor(usdAmountMinor: state.amountMinor, exchangeRateToUsd: state.customExchangeRate), currencyCode: 'ARS')} (${state.rateType.label})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.usdBadgeTextDark
                              : AppColors.usdBadgeTextLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: TextField(
                        onChanged: controller.updateNote,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.edit_note_rounded,
                            size: 18,
                          ),
                          hintText:
                              'Nota: ej. Carrefour, Burger, "En qué lo gasté"...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Grilla de Categorías Frecuentes (Toque 2)
            if (state.type != TransactionType.transfer)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Categoría',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (state.autoSaveOnCategoryTap)
                            const Text(
                              '⚡ Tocar categoría guarda directo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warningLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 82,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = filteredCategories[index];
                          final isSelected =
                              cat.id == state.selectedCategoryId;

                          return _CategoryQuickTile(
                            category: cat,
                            isSelected: isSelected,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              controller.selectCategory(cat.id);
                              if (state.autoSaveOnCategoryTap &&
                                  state.amountMinor > 0) {
                                handleSave();
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Teclado Numérico con tecla '+' (Suma Rápida) y '000' + Botón Guardar
            Expanded(
              flex: 5,
              child: _QuickNumericPad(
                onDigit: (d) {
                  HapticFeedback.lightImpact();
                  controller.appendDigit(d);
                },
                onBackspace: () {
                  HapticFeedback.selectionClick();
                  controller.backspace();
                },
                onClear: () {
                  HapticFeedback.mediumImpact();
                  controller.clearAmount();
                },
                onSubmit: handleSave,
                submitLabel: 'Guardar ${state.type.label}',
                accentColor: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTypeSelector extends StatelessWidget {
  const _TransactionTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TransactionType>(
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: const [
        ButtonSegment(
          value: TransactionType.expense,
          label: Text('Gasto'),
        ),
        ButtonSegment(
          value: TransactionType.income,
          label: Text('Ingreso'),
        ),
        ButtonSegment(
          value: TransactionType.transfer,
          label: Text('Transferir'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}

class _AccountSelectorChip extends StatelessWidget {
  const _AccountSelectorChip({
    required this.labelPrefix,
    required this.account,
    required this.accounts,
    required this.onSelected,
  });

  final String labelPrefix;
  final AccountEntity account;
  final List<AccountEntity> accounts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(account.icon, size: 18, color: account.color),
      label: Text(
        '$labelPrefix${account.name}',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Seleccionar cuenta',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                for (final item in accounts)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.color.withValues(alpha: 0.15),
                      child: Icon(item.icon, color: item.color),
                    ),
                    title: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      MoneyFormatter.formatMinor(
                        item.balanceMinor,
                        currencyCode: item.currencyCode,
                      ),
                    ),
                    trailing: item.id == account.id
                        ? const Icon(Icons.check_circle_rounded)
                        : null,
                    onTap: () {
                      onSelected(item.id);
                      Navigator.of(ctx).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExchangeRateChip extends StatelessWidget {
  const _ExchangeRateChip({
    required this.rateType,
    required this.rateValue,
    required this.onSelected,
  });

  final ExchangeRateType rateType;
  final double rateValue;
  final ValueChanged<ExchangeRateType> onSelected;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.currency_exchange_rounded, size: 16),
      label: Text(
        '${rateType.label}: \$${rateValue.toStringAsFixed(0)}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Cotización de referencia',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                for (final type in ExchangeRateType.values)
                  ListTile(
                    leading: const Icon(Icons.attach_money_rounded),
                    title: Text(type.label),
                    trailing: Text(
                      '\$ ${type.defaultSellRate.toStringAsFixed(0)} ARS',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    selected: type == rateType,
                    onTap: () {
                      onSelected(type);
                      Navigator.of(ctx).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryQuickTile extends StatelessWidget {
  const _CategoryQuickTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final CategoryEntity category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withValues(alpha: 0.18)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? category.color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(category.icon, color: category.color, size: 24),
            const SizedBox(height: 5),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickNumericPad extends StatelessWidget {
  const _QuickNumericPad({
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    required this.onSubmit,
    required this.submitLabel,
    required this.accentColor,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onSubmit;
  final String submitLabel;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3', '+'],
      ['4', '5', '6', '000'],
      ['7', '8', '9', 'BACK'],
      ['C', '0', '00', 'OK'],
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                for (final row in rows)
                  Expanded(
                    child: Row(
                      children: [
                        for (final key in row)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: _buildKeyButton(context, key),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
            ),
            onPressed: onSubmit,
            icon: const Icon(Icons.check_rounded),
            label: Text(submitLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyButton(BuildContext context, String key) {
    if (key == 'BACK') {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onBackspace,
        onLongPress: onClear,
        child: const Center(
          child: Icon(Icons.backspace_outlined, size: 22),
        ),
      );
    }
    if (key == 'C') {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onClear,
        child: const Center(
          child: Text(
            'C',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.expenseLight,
            ),
          ),
        ),
      );
    }
    if (key == 'OK') {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onSubmit,
        child: Container(
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Icon(Icons.check_rounded, color: accentColor, size: 24),
          ),
        ),
      );
    }
    final isSpecial = key == '+' || key == '000';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onDigit(key),
      child: Container(
        decoration: BoxDecoration(
          color: isSpecial
              ? AppColors.primaryLight.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            key,
            style: TextStyle(
              fontSize: key == '000' ? 17 : 22,
              fontWeight: FontWeight.w800,
              color: isSpecial ? AppColors.primaryLight : null,
            ),
          ),
        ),
      ),
    );
  }
}
