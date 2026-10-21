import 'package:flutter/material.dart';

/// Tipo de movimiento financiero.
enum TransactionType {
  expense('Gasto'),
  income('Ingreso'),
  transfer('Transferencia');

  const TransactionType(this.label);
  final String label;
}

/// Modo de valuación del tipo de cambio (Promedio Compra/Venta vs Venta vs Compra).
enum RateValuationMode {
  average('Promedio (Compra/Venta)'),
  sell('Precio Venta'),
  buy('Precio Compra');

  const RateValuationMode(this.label);
  final String label;
}

/// Tipos de cambio de referencia en Argentina con Dólar Oficial como predeterminado,
/// incluyendo precio de Compra, Venta y Promedio (Media).
enum ExchangeRateType {
  oficial('Dólar Oficial', 975.0, 1015.0),
  mep('Dólar MEP', 1185.0, 1195.0),
  blue('Dólar Blue', 1200.0, 1220.0),
  tarjeta('Dólar Tarjeta', 1580.0, 1580.0);

  const ExchangeRateType(this.label, this.defaultBuyRate, this.defaultSellRate);
  final String label;
  final double defaultBuyRate;
  final double defaultSellRate;

  /// Promedio (Media) entre Compra y Venta: ideal para valuar balances sin sesgo.
  double get defaultAverageRate => (defaultBuyRate + defaultSellRate) / 2.0;
}

/// Estado de sincronización Offline-First (Cola Outbox).
enum SyncStatus {
  synced,
  pendingPush,
  pendingDelete,
}

/// Meses disponibles para filtrado histórico y planificación a 1 mes adelantado.
enum MonthPeriod {
  nov2026('2026-11', 'Noviembre 2026 ⏭️'),
  oct2026('2026-10', 'Octubre 2026'),
  sep2026('2026-09', 'Septiembre 2026'),
  aug2026('2026-08', 'Agosto 2026');

  const MonthPeriod(this.key, this.label);
  final String key;
  final String label;
}

/// Entidad de Gasto Fijo / Pago Mensual completamente editable (nombre, categoría,
/// monto, pago parcial, fecha límite y nota).
class MonthlyBillEntity {
  const MonthlyBillEntity({
    required this.id,
    required this.monthKey, // '2026-10' | '2026-09' | '2026-08'
    required this.title,
    required this.categoryId,
    required this.amountMinor,
    this.paidAmountMinor,
    required this.isPaid,
    required this.dueDateLabel, // Ej: 'Vence 05/10'
    this.note = '',
  });

  final String id;
  final String monthKey;
  final String title;
  final String categoryId;
  final int amountMinor; // En centavos de ARS
  final int? paidAmountMinor; // Para pagos parciales (ej: Alquiler pagué 300.000 de 780.000)
  final bool isPaid;
  final String dueDateLabel;
  final String note;

  int get pendingMinor {
    if (isPaid) return 0;
    if (paidAmountMinor != null && paidAmountMinor! < amountMinor) {
      return amountMinor - paidAmountMinor!;
    }
    return amountMinor;
  }

  MonthlyBillEntity copyWith({
    String? title,
    String? categoryId,
    int? amountMinor,
    int? paidAmountMinor,
    bool clearPaidAmount = false,
    bool? isPaid,
    String? dueDateLabel,
    String? note,
  }) {
    return MonthlyBillEntity(
      id: id,
      monthKey: monthKey,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      amountMinor: amountMinor ?? this.amountMinor,
      paidAmountMinor:
          clearPaidAmount ? null : (paidAmountMinor ?? this.paidAmountMinor),
      isPaid: isPaid ?? this.isPaid,
      dueDateLabel: dueDateLabel ?? this.dueDateLabel,
      note: note ?? this.note,
    );
  }
}

/// Entidad de Cuenta / Billetera (Efectivo, Banco, Billetera Virtual, Tarjeta).
class AccountEntity {
  const AccountEntity({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.balanceMinor,
    required this.icon,
    required this.color,
    this.accountTypeLabel = 'Billetera',
  });

  final String id;
  final String name;
  final String currencyCode; // 'ARS' | 'USD'
  final int balanceMinor; // En centavos
  final IconData icon;
  final Color color;
  final String accountTypeLabel;

  AccountEntity copyWith({
    String? name,
    int? balanceMinor,
    IconData? icon,
  }) {
    return AccountEntity(
      id: id,
      name: name ?? this.name,
      currencyCode: currencyCode,
      balanceMinor: balanceMinor ?? this.balanceMinor,
      icon: icon ?? this.icon,
      color: color,
      accountTypeLabel: accountTypeLabel,
    );
  }
}

/// Entidad de Categoría personalizable con ícono, color y tope de presupuesto mensual.
class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.kind,
    required this.icon,
    required this.color,
    this.monthlyBudgetArsMinor,
  });

  final String id;
  final String name;
  final TransactionType kind;
  final IconData icon;
  final Color color;
  final int? monthlyBudgetArsMinor;

  CategoryEntity copyWith({
    String? name,
    IconData? icon,
    int? monthlyBudgetArsMinor,
  }) {
    return CategoryEntity(
      id: id,
      name: name ?? this.name,
      kind: kind,
      icon: icon ?? this.icon,
      color: color,
      monthlyBudgetArsMinor:
          monthlyBudgetArsMinor ?? this.monthlyBudgetArsMinor,
    );
  }
}

/// Entidad de Meta de Ahorro (en USD o ARS) con seguimiento de progreso.
class SavingsGoalEntity {
  const SavingsGoalEntity({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.targetAmountMinor,
    required this.currentAmountMinor,
    required this.linkedAccountId,
    required this.icon,
    required this.color,
    this.targetDateLabel = 'Diciembre 2026',
  });

  final String id;
  final String name;
  final String currencyCode; // 'USD' | 'ARS'
  final int targetAmountMinor;
  final int currentAmountMinor;
  final String linkedAccountId;
  final IconData icon;
  final Color color;
  final String targetDateLabel;

  double get progress => targetAmountMinor <= 0
      ? 0
      : (currentAmountMinor / targetAmountMinor).clamp(0.0, 1.0);

  SavingsGoalEntity copyWith({
    int? currentAmountMinor,
    int? targetAmountMinor,
  }) {
    return SavingsGoalEntity(
      id: id,
      name: name,
      currencyCode: currencyCode,
      targetAmountMinor: targetAmountMinor ?? this.targetAmountMinor,
      currentAmountMinor: currentAmountMinor ?? this.currentAmountMinor,
      linkedAccountId: linkedAccountId,
      icon: icon,
      color: color,
      targetDateLabel: targetDateLabel,
    );
  }
}

/// Entidad de Regla de Transacción Recurrente.
class RecurringRuleEntity {
  const RecurringRuleEntity({
    required this.id,
    required this.title,
    required this.type,
    required this.accountId,
    required this.categoryId,
    required this.amountMinor,
    required this.currencyCode,
    required this.dayOfMonth,
    required this.rateType,
    this.isActive = true,
  });

  final String id;
  final String title;
  final TransactionType type;
  final String accountId;
  final String categoryId;
  final int amountMinor;
  final String currencyCode;
  final int dayOfMonth;
  final ExchangeRateType rateType;
  final bool isActive;
}

/// Entidad de Transacción con huella bimonetaria y clave de mes (`monthKey`).
class TransactionEntity {
  const TransactionEntity({
    required this.id,
    required this.monthKey,
    required this.dayLabel,
    required this.type,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    required this.amountMinor,
    required this.currencyCode,
    this.toAmountMinor,
    required this.exchangeRateType,
    required this.exchangeRateToUsd,
    required this.amountUsdMinor,
    required this.transactionDate,
    this.note = '',
    this.syncStatus = SyncStatus.pendingPush,
  });

  final String id;
  final String monthKey;
  final String dayLabel;
  final TransactionType type;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final int amountMinor;
  final String currencyCode;
  final int? toAmountMinor;
  final ExchangeRateType exchangeRateType;
  final double exchangeRateToUsd;
  final int amountUsdMinor;
  final DateTime transactionDate;
  final String note;
  final SyncStatus syncStatus;
}
