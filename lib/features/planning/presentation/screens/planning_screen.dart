import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../transactions/domain/entities/transaction_models.dart';
import '../../../transactions/presentation/controllers/quick_transaction_controller.dart';

/// Pestaña 3: Gastos Fijos del Mes con edición completa (Nombre, Categoría, Monto,
/// Pago Parcial, Fecha Límite, Nota y Eliminar) + Agregar Nuevo Gasto Fijo.
class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final allBills = ref.watch(monthlyBillsProvider);
    final fixedCategories = ref.watch(fixedBillCategoriesProvider);
    final goals = ref.watch(savingsGoalsProvider);

    final monthBills =
        allBills.where((b) => b.monthKey == selectedMonth.key).toList();

    int totalBillsMinor = 0;
    int paidBillsMinor = 0;
    int pendingBillsMinor = 0;

    for (final b in monthBills) {
      totalBillsMinor += b.amountMinor;
      if (b.isPaid) {
        paidBillsMinor += b.amountMinor;
      } else {
        final partial = b.paidAmountMinor ?? 0;
        paidBillsMinor += partial;
        pendingBillsMinor += (b.amountMinor - partial);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Fijos del Mes'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: const Text('Agregar Fijo'),
              onPressed: () => _showAddBillDialog(
                context,
                ref,
                selectedMonth.key,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
        children: [
          // 0. Selector de Mes (Noviembre / Octubre / Septiembre / Agosto 2026)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final m in MonthPeriod.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        m.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      selected: m == selectedMonth,
                      onSelected: (_) {
                        ref.read(selectedMonthProvider.notifier).state = m;
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 1. Tarjeta Resumen de Gastos Fijos del Mes en ARS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gastos Fijos (${selectedMonth.label})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      MoneyFormatter.formatMinor(
                        totalBillsMinor,
                        currencyCode: 'ARS',
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalBillsMinor > 0
                        ? (paidBillsMinor / totalBillsMinor).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 8,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '✅ Ya pagado: ${MoneyFormatter.formatMinor(paidBillsMinor, currencyCode: 'ARS')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.incomeLight,
                      ),
                    ),
                    Text(
                      '⏳ Falta pagar: ${MoneyFormatter.formatMinor(pendingBillsMinor, currencyCode: 'ARS')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.expenseLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Checklist de Gastos Fijos del Mes (Tocá cualquiera para modificar nombre, monto, fecha o nota)
          for (final bill in monthBills)
            _MonthlyBillCard(
              bill: bill,
              category: fixedCategories
                  .where((c) => c.id == bill.categoryId)
                  .firstOrNull,
              onTogglePaid: () {
                ref
                    .read(monthlyBillsProvider.notifier)
                    .toggleBillPaid(bill.id);
              },
              onEditBill: () => _showEditBillDialog(
                context,
                ref,
                bill,
              ),
            ),

          const SizedBox(height: 24),

          // 3. Metas de Ahorro y Colchón Fin de Mes
          const Text(
            'Colchón y Metas de Ahorro',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final goal in goals)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: goal.color.withValues(alpha: 0.15),
                          child: Icon(goal.icon, color: goal.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            goal.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Aportar'),
                          onPressed: () {
                            final stepMinor = goal.currencyCode == 'USD'
                                ? 10000
                                : 5000000;
                            ref
                                .read(savingsGoalsProvider.notifier)
                                .addContribution(goal.id, stepMinor);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 8,
                        color: goal.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ahorrado: ${MoneyFormatter.formatMinor(goal.currentAmountMinor, currencyCode: goal.currencyCode)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Meta: ${MoneyFormatter.formatMinor(goal.targetAmountMinor, currencyCode: goal.currencyCode)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _parseSumFormula(String input) {
    final parts = input.split('+');
    int total = 0;
    for (final p in parts) {
      final clean = p.replaceAll('.', '').trim();
      total += int.tryParse(clean) ?? 0;
    }
    return total;
  }

  /// Modal de Edición Completa: permite modificar Nombre, Categoría de Gasto Fijo
  /// (con opción de cargar una nueva categoría in-situ), Monto total, Pago Parcial,
  /// Fecha Límite, Nota o Eliminar el gasto fijo.
  void _showEditBillDialog(
    BuildContext context,
    WidgetRef ref,
    MonthlyBillEntity bill,
  ) {
    final titleCtrl = TextEditingController(text: bill.title);
    final amountCtrl = TextEditingController(
      text: (bill.amountMinor ~/ 100).toString(),
    );
    final partialCtrl = TextEditingController(
      text: bill.paidAmountMinor != null
          ? (bill.paidAmountMinor! ~/ 100).toString()
          : '',
    );
    final dueCtrl = TextEditingController(text: bill.dueDateLabel);
    final noteCtrl = TextEditingController(text: bill.note);
    final newCatCtrl = TextEditingController();
    bool showNewCatInput = false;
    String selectedCategoryId = bill.categoryId;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final fixedCategories = ref.read(fixedBillCategoriesProvider);
          final validSelectedId =
              fixedCategories.any((c) => c.id == selectedCategoryId)
                  ? selectedCategoryId
                  : fixedCategories.first.id;

          return AlertDialog(
            title: const Text('Modificar Gasto Fijo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del gasto fijo',
                      hintText: 'Ej: Servicio o pago mensual',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: validSelectedId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría de Gasto Fijo',
                    ),
                    items: [
                      for (final c in fixedCategories)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedCategoryId = v);
                      }
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Nueva categoría de gasto fijo'),
                      onPressed: () {
                        setDialogState(
                          () => showNewCatInput = !showNewCatInput,
                        );
                      },
                    ),
                  ),
                  if (showNewCatInput) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newCatCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Nombre de la categoría...',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () {
                            final name = newCatCtrl.text.trim();
                            if (name.isEmpty) return;
                            ref
                                .read(fixedBillCategoriesProvider.notifier)
                                .addCategory(name);
                            final updated =
                                ref.read(fixedBillCategoriesProvider);
                            setDialogState(() {
                              selectedCategoryId = updated.last.id;
                              newCatCtrl.clear();
                              showNewCatInput = false;
                            });
                          },
                          child: const Text('Cargar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Monto total ARS',
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: partialCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pago parcial abonado (ARS)',
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dueCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Fecha límite de pago',
                      hintText: 'Ej: Día 10',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Nota o comentario (opcional)',
                      hintText: 'Ej: Detalle adicional del pago',
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton.icon(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.expenseLight,
                ),
                label: const Text(
                  'Eliminar',
                  style: TextStyle(color: AppColors.expenseLight),
                ),
                onPressed: () {
                  ref.read(monthlyBillsProvider.notifier).deleteBill(bill.id);
                  Navigator.of(ctx).pop();
                },
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final sumMajor = _parseSumFormula(amountCtrl.text);
                      final partialMajor =
                          int.tryParse(partialCtrl.text.trim()) ?? 0;
                      if (titleCtrl.text.trim().isNotEmpty && sumMajor > 0) {
                        ref.read(monthlyBillsProvider.notifier).updateBillFull(
                              billId: bill.id,
                              title: titleCtrl.text.trim(),
                              categoryId: validSelectedId,
                              amountMinor: sumMajor * 100,
                              paidAmountMinor:
                                  partialMajor > 0 ? partialMajor * 100 : null,
                              dueDateLabel: dueCtrl.text.trim(),
                              note: noteCtrl.text.trim(),
                            );
                        Navigator.of(ctx).pop();
                      }
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddBillDialog(
    BuildContext context,
    WidgetRef ref,
    String monthKey,
  ) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final dueCtrl = TextEditingController(text: 'Día 10');
    final noteCtrl = TextEditingController();
    final newCatCtrl = TextEditingController();
    bool showNewCatInput = false;
    String selectedCategoryId =
        ref.read(fixedBillCategoriesProvider).first.id;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final fixedCategories = ref.read(fixedBillCategoriesProvider);
          final validSelectedId =
              fixedCategories.any((c) => c.id == selectedCategoryId)
                  ? selectedCategoryId
                  : fixedCategories.first.id;

          return AlertDialog(
            title: const Text('Agregar Gasto Fijo al Mes'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del gasto fijo',
                      hintText: 'Ej: Servicio o pago mensual',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: validSelectedId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría de Gasto Fijo',
                    ),
                    items: [
                      for (final c in fixedCategories)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedCategoryId = v);
                      }
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Nueva categoría de gasto fijo'),
                      onPressed: () {
                        setDialogState(
                          () => showNewCatInput = !showNewCatInput,
                        );
                      },
                    ),
                  ),
                  if (showNewCatInput) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newCatCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Nombre de la categoría...',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: () {
                            final name = newCatCtrl.text.trim();
                            if (name.isEmpty) return;
                            ref
                                .read(fixedBillCategoriesProvider.notifier)
                                .addCategory(name);
                            final updated =
                                ref.read(fixedBillCategoriesProvider);
                            setDialogState(() {
                              selectedCategoryId = updated.last.id;
                              newCatCtrl.clear();
                              showNewCatInput = false;
                            });
                          },
                          child: const Text('Cargar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Monto total en ARS',
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dueCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Fecha límite de pago',
                      hintText: 'Ej: Día 10',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nota o comentario (opcional)',
                      hintText: 'Ej: Detalle adicional del pago',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final sumMajor = _parseSumFormula(amountCtrl.text);
                  if (titleCtrl.text.trim().isNotEmpty && sumMajor > 0) {
                    ref.read(monthlyBillsProvider.notifier).addBill(
                          monthKey: monthKey,
                          title: titleCtrl.text.trim(),
                          categoryId: validSelectedId,
                          amountMinor: sumMajor * 100,
                          dueDateLabel: dueCtrl.text.trim(),
                          note: noteCtrl.text.trim(),
                        );
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthlyBillCard extends StatelessWidget {
  const _MonthlyBillCard({
    required this.bill,
    required this.category,
    required this.onTogglePaid,
    required this.onEditBill,
  });

  final MonthlyBillEntity bill;
  final CategoryEntity? category;
  final VoidCallback onTogglePaid;
  final VoidCallback onEditBill;

  @override
  Widget build(BuildContext context) {
    final hasPartial = !bill.isPaid &&
        bill.paidAmountMinor != null &&
        bill.paidAmountMinor! > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onEditBill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: bill.isPaid,
                activeColor: AppColors.primaryLight,
                onChanged: (_) => onTogglePaid(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bill.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              decoration: bill.isPaid
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        Text(
                          MoneyFormatter.formatMinor(
                            bill.amountMinor,
                            currencyCode: 'ARS',
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: bill.isPaid
                                ? AppColors.incomeLight
                                : AppColors.expenseLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: bill.isPaid
                                ? AppColors.incomeLight.withValues(alpha: 0.14)
                                : AppColors.warningLight.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bill.isPaid
                                ? '✓ Pagado • ${bill.dueDateLabel}'
                                : hasPartial
                                    ? '🌗 Parcial (${MoneyFormatter.formatMinor(bill.paidAmountMinor!, currencyCode: 'ARS')}) • ${bill.dueDateLabel}'
                                    : '⏳ ${bill.dueDateLabel}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: bill.isPaid
                                  ? AppColors.incomeLight
                                  : AppColors.warningLight,
                            ),
                          ),
                        ),
                        const Text(
                          '✏️ Modificar nombre / monto / nota',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (bill.note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '📝 ${bill.note}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
