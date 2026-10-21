import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../transactions/domain/entities/transaction_models.dart';

class CategoryExpenseSlice {
  const CategoryExpenseSlice({
    required this.category,
    required this.amountMinor,
    required this.percentage,
  });

  final CategoryEntity category;
  final int amountMinor;
  final double percentage;
}

/// Tarjeta con Gráfico de Dona (CustomPainter a 60/120fps) y desglose porcentual
/// de gastos del mes por categoría en la moneda activa (ARS o USD).
class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({
    super.key,
    required this.transactions,
    required this.categories,
    required this.displayCurrency,
  });

  final List<TransactionEntity> transactions;
  final List<CategoryEntity> categories;
  final String displayCurrency;

  @override
  Widget build(BuildContext context) {
    final Map<String, int> totalsByCategory = {};
    int totalExpensesMinor = 0;

    for (final tx in transactions) {
      if (tx.type != TransactionType.expense || tx.categoryId == null) continue;
      final int value = displayCurrency == 'USD'
          ? tx.amountUsdMinor
          : (tx.currencyCode == 'ARS'
              ? tx.amountMinor
              : MoneyFormatter.convertUsdMinorToArsMinor(
                  usdAmountMinor: tx.amountMinor,
                  exchangeRateToUsd: tx.exchangeRateToUsd,
                ));

      totalsByCategory[tx.categoryId!] =
          (totalsByCategory[tx.categoryId!] ?? 0) + value;
      totalExpensesMinor += value;
    }

    final List<CategoryExpenseSlice> slices = [];
    if (totalExpensesMinor > 0) {
      for (final entry in totalsByCategory.entries) {
        final cat = categories.where((c) => c.id == entry.key).firstOrNull;
        if (cat != null) {
          slices.add(
            CategoryExpenseSlice(
              category: cat,
              amountMinor: entry.value,
              percentage: (entry.value / totalExpensesMinor) * 100.0,
            ),
          );
        }
      }
      slices.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gastos por Categoría',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  MoneyFormatter.formatMinor(
                    totalExpensesMinor,
                    currencyCode: displayCurrency,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (slices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Aún no hay gastos registrados este mes.'),
                ),
              )
            else
              Row(
                children: [
                  SizedBox(
                    width: 116,
                    height: 116,
                    child: CustomPaint(
                      painter: _DonutChartPainter(slices: slices),
                      child: Center(
                        child: Text(
                          '${slices.length}\ncateg.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        for (final slice in slices.take(4))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: slice.category.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    slice.category.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${slice.percentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.slices});

  final List<CategoryExpenseSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const strokeWidth = 18.0;

    double startAngle = -math.pi / 2;

    for (final slice in slices) {
      final sweepAngle = (slice.percentage / 100.0) * 2 * math.pi;
      final paint = Paint()
        ..color = slice.category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.max(0.02, sweepAngle - 0.04),
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.slices != slices;
  }
}

