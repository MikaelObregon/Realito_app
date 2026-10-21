import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/exchange_rate_service.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/entities/transaction_models.dart';

/// Moneda de visualización activa en el Dashboard (Switch 1-toque ARS ⇄ USD).
final dashboardDisplayCurrencyProvider = StateProvider<String>((ref) => 'ARS');

/// Mes seleccionado globalmente (Noviembre 2026 adelantado, Octubre, Septiembre, Agosto 2026).
final selectedMonthProvider =
    StateProvider<MonthPeriod>((ref) => MonthPeriod.oct2026);

/// Fecha configurada del próximo cobro (para calcular cuánto se puede gastar por día con precisión).
final nextPaydayDateProvider =
    StateProvider<DateTime>((ref) => DateTime(2026, 11, 5));

/// Registro de meses anteriores cuyo saldo positivo a favor fue transferido manualmente al mes siguiente.
final transferredSurplusMonthsProvider =
    StateProvider<Set<String>>((ref) => <String>{});

/// Proveedor de cuentas y billeteras.
final accountsProvider =
    StateNotifierProvider<AccountsNotifier, List<AccountEntity>>((ref) {
  return AccountsNotifier();
});

class AccountsNotifier extends StateNotifier<List<AccountEntity>> {
  AccountsNotifier()
      : super(const [
          AccountEntity(
            id: 'acc_mp_ars',
            name: 'Personal Pay',
            currencyCode: 'ARS',
            balanceMinor: 48500000,
            icon: Icons.account_balance_wallet_rounded,
            color: Color(0xFF6366F1),
            accountTypeLabel: 'Billetera Virtual',
          ),
          AccountEntity(
            id: 'acc_bank_ars',
            name: 'Cuenta Sueldo / Banco',
            currencyCode: 'ARS',
            balanceMinor: 92000000,
            icon: Icons.account_balance_rounded,
            color: Color(0xFFEA580C),
            accountTypeLabel: 'Caja de Ahorro',
          ),
          AccountEntity(
            id: 'acc_cash_ars',
            name: 'Efectivo ARS',
            currencyCode: 'ARS',
            balanceMinor: 4500000,
            icon: Icons.payments_rounded,
            color: Color(0xFF16A34A),
            accountTypeLabel: 'Efectivo',
          ),
          AccountEntity(
            id: 'acc_usd_savings',
            name: 'Ahorro USD',
            currencyCode: 'USD',
            balanceMinor: 145000,
            icon: Icons.savings_rounded,
            color: Color(0xFF0D7A5F),
            accountTypeLabel: 'Moneda Dura',
          ),
        ]);

  void addAccount({
    required String name,
    required String currencyCode,
    required int initialBalanceMinor,
    required String accountTypeLabel,
  }) {
    final newAcc = AccountEntity(
      id: 'acc_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      currencyCode: currencyCode,
      balanceMinor: initialBalanceMinor,
      icon: currencyCode == 'USD'
          ? Icons.savings_rounded
          : Icons.account_balance_wallet_rounded,
      color: currencyCode == 'USD'
          ? const Color(0xFF0D7A5F)
          : const Color(0xFF6366F1),
      accountTypeLabel: accountTypeLabel,
    );
    state = [...state, newAcc];
  }

  void updateAccount({
    required String accountId,
    required String name,
    required int balanceMinor,
  }) {
    state = [
      for (final acc in state)
        if (acc.id == accountId)
          acc.copyWith(name: name, balanceMinor: balanceMinor)
        else
          acc,
    ];
  }

  void deleteAccount(String accountId) {
    if (state.length <= 1) return;
    state = state.where((acc) => acc.id != accountId).toList();
  }

  void applyTransaction(TransactionEntity tx) {
    state = [
      for (final acc in state)
        if (acc.id == tx.accountId)
          acc.copyWith(
            balanceMinor: tx.type == TransactionType.income
                ? acc.balanceMinor + tx.amountMinor
                : acc.balanceMinor - tx.amountMinor,
          )
        else if (tx.type == TransactionType.transfer &&
            acc.id == tx.toAccountId)
          acc.copyWith(
            balanceMinor:
                acc.balanceMinor + (tx.toAmountMinor ?? tx.amountMinor),
          )
        else
          acc,
    ];
  }

  /// Revierte el impacto de una transacción en las cuentas (usado al editar o eliminar un movimiento).
  void revertTransaction(TransactionEntity tx) {
    state = [
      for (final acc in state)
        if (acc.id == tx.accountId)
          acc.copyWith(
            balanceMinor: tx.type == TransactionType.income
                ? acc.balanceMinor - tx.amountMinor
                : acc.balanceMinor + tx.amountMinor,
          )
        else if (tx.type == TransactionType.transfer &&
            acc.id == tx.toAccountId)
          acc.copyWith(
            balanceMinor:
                acc.balanceMinor - (tx.toAmountMinor ?? tx.amountMinor),
          )
        else
          acc,
    ];
  }

  /// Transfiere saldo entre dos cuentas propias sin afectar Ingresos ni Gastos del mes.
  bool transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required int amountMinor,
  }) {
    if (fromAccountId == toAccountId || amountMinor <= 0) return false;
    state = [
      for (final acc in state)
        if (acc.id == fromAccountId)
          acc.copyWith(balanceMinor: acc.balanceMinor - amountMinor)
        else if (acc.id == toAccountId)
          acc.copyWith(balanceMinor: acc.balanceMinor + amountMinor)
        else
          acc,
    ];
    return true;
  }
}

/// Categorías exclusivas para GASTOS FIJOS MENSUALES (separadas de Gastos Diarios).
final fixedBillCategoriesProvider = StateNotifierProvider<
    FixedBillCategoriesNotifier, List<CategoryEntity>>((ref) {
  return FixedBillCategoriesNotifier();
});

class FixedBillCategoriesNotifier extends StateNotifier<List<CategoryEntity>> {
  FixedBillCategoriesNotifier()
      : super(const [
          CategoryEntity(
            id: 'fcat_vivienda',
            name: 'Vivienda / Alquiler',
            kind: TransactionType.expense,
            icon: Icons.home_rounded,
            color: Color(0xFF7C3AED),
          ),
          CategoryEntity(
            id: 'fcat_servicios',
            name: 'Servicios (Luz / Gas / Internet)',
            kind: TransactionType.expense,
            icon: Icons.bolt_rounded,
            color: Color(0xFF6366F1),
          ),
          CategoryEntity(
            id: 'fcat_educacion',
            name: 'Colegio / Educación',
            kind: TransactionType.expense,
            icon: Icons.school_rounded,
            color: Color(0xFF0284C7),
          ),
          CategoryEntity(
            id: 'fcat_tarjetas',
            name: 'Tarjetas / Cuotas',
            kind: TransactionType.expense,
            icon: Icons.credit_card_rounded,
            color: Color(0xFFD97706),
          ),
          CategoryEntity(
            id: 'fcat_seguro_auto',
            name: 'Seguro / Auto Fijo',
            kind: TransactionType.expense,
            icon: Icons.directions_car_rounded,
            color: Color(0xFF2563EB),
          ),
          CategoryEntity(
            id: 'fcat_familia',
            name: 'Mensualidad / Familia',
            kind: TransactionType.expense,
            icon: Icons.favorite_rounded,
            color: Color(0xFFDB2777),
          ),
          CategoryEntity(
            id: 'fcat_suscripciones',
            name: 'Suscripciones / Nube',
            kind: TransactionType.expense,
            icon: Icons.cloud_done_rounded,
            color: Color(0xFF14B8A6),
          ),
        ]);

  CategoryEntity addCategory(String name, {IconData? icon}) {
    return addFixedCategory(name, icon: icon);
  }

  CategoryEntity addFixedCategory(String name, {IconData? icon}) {
    final newCat = CategoryEntity(
      id: 'fcat_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      kind: TransactionType.expense,
      icon: icon ?? Icons.bookmark_added_rounded,
      color: const Color(0xFF10B981),
    );
    state = [...state, newCat];
    return newCat;
  }

  void updateFixedCategory(
    String categoryId, {
    String? name,
    IconData? icon,
  }) {
    state = [
      for (final c in state)
        if (c.id == categoryId)
          c.copyWith(name: name, icon: icon)
        else
          c,
    ];
  }

  void deleteFixedCategory(String categoryId) {
    if (state.length <= 1) return;
    state = state.where((c) => c.id != categoryId).toList();
  }
}

/// Categorías separadas por Gastos Diarios e Ingresos (Sueldo, Adelanto de sueldo, Préstamo, Uber/DiDi).
final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<CategoryEntity>>((ref) {
  return CategoriesNotifier();
});

class CategoriesNotifier extends StateNotifier<List<CategoryEntity>> {
  CategoriesNotifier()
      : super(const [
          CategoryEntity(
            id: 'cat_super',
            name: 'Súper / Carnicería / Verdulería',
            kind: TransactionType.expense,
            icon: Icons.shopping_cart_rounded,
            color: Color(0xFFE11D48),
            monthlyBudgetArsMinor: 35000000,
          ),
          CategoryEntity(
            id: 'cat_emilis',
            name: 'Emilis',
            kind: TransactionType.expense,
            icon: Icons.favorite_rounded,
            color: Color(0xFFDB2777),
            monthlyBudgetArsMinor: 18000000,
          ),
          CategoryEntity(
            id: 'cat_auto_transporte',
            name: 'Auto / Nafta / SUBE / Uber',
            kind: TransactionType.expense,
            icon: Icons.directions_car_rounded,
            color: Color(0xFF2563EB),
            monthlyBudgetArsMinor: 20000000,
          ),
          CategoryEntity(
            id: 'cat_comida',
            name: 'Comida Rápida / Panadería / Kiosco',
            kind: TransactionType.expense,
            icon: Icons.fastfood_rounded,
            color: Color(0xFFF97316),
            monthlyBudgetArsMinor: 12000000,
          ),
          CategoryEntity(
            id: 'cat_personal',
            name: 'Peluquería / Farmacia / Otros',
            kind: TransactionType.expense,
            icon: Icons.content_cut_rounded,
            color: Color(0xFF0D9488),
            monthlyBudgetArsMinor: 10000000,
          ),
          // Categorías exclusivas de Ingreso (configuración propia)
          CategoryEntity(
            id: 'cat_sueldo',
            name: 'Sueldo',
            kind: TransactionType.income,
            icon: Icons.work_rounded,
            color: Color(0xFF16A34A),
          ),
          CategoryEntity(
            id: 'cat_adelanto',
            name: 'Adelanto de sueldo',
            kind: TransactionType.income,
            icon: Icons.bolt_rounded,
            color: Color(0xFF059669),
          ),
          CategoryEntity(
            id: 'cat_prestamo',
            name: 'Préstamo',
            kind: TransactionType.income,
            icon: Icons.handshake_rounded,
            color: Color(0xFF0EA5E9),
          ),
          CategoryEntity(
            id: 'cat_uber_didi',
            name: 'Uber / DiDi',
            kind: TransactionType.income,
            icon: Icons.local_taxi_rounded,
            color: Color(0xFFF59E0B),
          ),
        ]);

  void addCategory({
    required String name,
    required TransactionType kind,
    int? monthlyBudgetArsMinor,
  }) {
    final newCat = CategoryEntity(
      id: 'cat_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      kind: kind,
      icon: kind == TransactionType.income
          ? Icons.attach_money_rounded
          : Icons.category_rounded,
      color: kind == TransactionType.income
          ? const Color(0xFF10B981)
          : const Color(0xFF6366F1),
      monthlyBudgetArsMinor: monthlyBudgetArsMinor,
    );
    state = [...state, newCat];
  }

  void renameCategory(String categoryId, String newName) {
    state = [
      for (final c in state)
        if (c.id == categoryId) c.copyWith(name: newName) else c,
    ];
  }

  void updateCategory(
    String categoryId, {
    String? name,
    IconData? icon,
  }) {
    state = [
      for (final c in state)
        if (c.id == categoryId)
          c.copyWith(name: name, icon: icon)
        else
          c,
    ];
  }

  void deleteCategory(String categoryId) {
    state = state.where((c) => c.id != categoryId).toList();
  }

  void updateBudget(String categoryId, int newBudgetArsMinor) {
    state = [
      for (final c in state)
        if (c.id == categoryId)
          c.copyWith(monthlyBudgetArsMinor: newBudgetArsMinor)
        else
          c,
    ];
  }

  void adjustAllBudgetsByInflation(double percentage) {
    final factor = 1.0 + (percentage / 100.0);
    state = [
      for (final c in state)
        if (c.monthlyBudgetArsMinor != null)
          c.copyWith(
            monthlyBudgetArsMinor:
                ((c.monthlyBudgetArsMinor! * factor) / 100000).round() * 100000,
          )
        else
          c,
    ];
  }
}

/// Proveedor de "Pagos del Mes (Gastos Fijos)" con check de pagado, fecha límite y notas
/// precargado con tus datos reales de Octubre, Septiembre y Agosto 2026.
final monthlyBillsProvider =
    StateNotifierProvider<MonthlyBillsNotifier, List<MonthlyBillEntity>>((ref) {
  return MonthlyBillsNotifier();
});

class MonthlyBillsNotifier extends StateNotifier<List<MonthlyBillEntity>> {
  MonthlyBillsNotifier()
      : super(const [
          // ==================== OCTUBRE 2026 ====================
          MonthlyBillEntity(
            id: 'bill_oct_alquiler',
            monthKey: '2026-10',
            title: 'Alquiler',
            categoryId: 'cat_hogar',
            amountMinor: 78000000, // $ 780.000
            isPaid: true,
            dueDateLabel: 'Vence 05/10',
            note: 'Pago mensual alquiler',
          ),
          MonthlyBillEntity(
            id: 'bill_oct_luz_marina',
            monthKey: '2026-10',
            title: 'Luz Marina',
            categoryId: 'cat_emilis',
            amountMinor: 25700000, // $ 257.000
            isPaid: true,
            dueDateLabel: 'Vence 10/10',
            note: '7.000 + 200.000 + 30.000 + 20.000',
          ),
          MonthlyBillEntity(
            id: 'bill_oct_colegio',
            monthKey: '2026-10',
            title: 'Colegio',
            categoryId: 'cat_colegio',
            amountMinor: 17707200, // $ 177.072
            isPaid: true,
            dueDateLabel: 'Vence 10/10',
            note: 'Cuota mensual colegio',
          ),
          MonthlyBillEntity(
            id: 'bill_oct_seguro_auto',
            monthKey: '2026-10',
            title: 'Seguro Auto',
            categoryId: 'cat_auto_transporte',
            amountMinor: 15000000, // $ 150.000
            isPaid: false,
            dueDateLabel: 'Vence 15/10',
            note:
                '(debería de gastarlo en aceite y consumo de nafta) 15 gasolina + 10 limpiador + 15 gasolina',
          ),
          MonthlyBillEntity(
            id: 'bill_oct_dia_madres',
            monthKey: '2026-10',
            title: 'Día de las Madres',
            categoryId: 'cat_personal',
            amountMinor: 6000000, // $ 60.000
            isPaid: true,
            dueDateLabel: 'Vence 18/10',
            note: '8 cartera + 29 aros',
          ),
          MonthlyBillEntity(
            id: 'bill_oct_gocuotas',
            monthKey: '2026-10',
            title: 'Go Cuotas',
            categoryId: 'cat_cuotas',
            amountMinor: 5289200, // $ 52.892
            isPaid: true,
            dueDateLabel: 'Vence 10/10',
            note: 'Cuotas del mes',
          ),
          MonthlyBillEntity(
            id: 'bill_oct_emilis',
            monthKey: '2026-10',
            title: 'Emilis (Fijo)',
            categoryId: 'cat_emilis',
            amountMinor: 5000000, // $ 50.000
            isPaid: true,
            dueDateLabel: 'Vence 05/10',
            note: 'Base mensual Emilis',
          ),
          MonthlyBillEntity(
            id: 'bill_oct_mp',
            monthKey: '2026-10',
            title: 'Mercado Pago',
            categoryId: 'cat_cuotas',
            amountMinor: 4857000, // $ 48.570
            isPaid: true,
            dueDateLabel: 'Vence 08/10',
            note: 'Resumen Mercado Pago',
          ),
          MonthlyBillEntity(
            id: 'bill_oct_luz',
            monthKey: '2026-10',
            title: 'Luz',
            categoryId: 'cat_hogar',
            amountMinor: 4252700, // $ 42.527
            isPaid: true,
            dueDateLabel: 'Vence 12/10',
            note: 'Factura electricidad',
          ),
          MonthlyBillEntity(
            id: 'bill_oct_corte_pelo',
            monthKey: '2026-10',
            title: 'Corte de pelo',
            categoryId: 'cat_personal',
            amountMinor: 3300000, // $ 33.000
            isPaid: true,
            dueDateLabel: 'Vence 10/10',
            note: '20.000 + 13.000',
          ),
          MonthlyBillEntity(
            id: 'bill_oct_internet',
            monthKey: '2026-10',
            title: 'Internet',
            categoryId: 'cat_hogar',
            amountMinor: 2437100, // $ 24.371
            isPaid: false,
            dueDateLabel: 'Vence 18/10',
            note: 'Fibra hogar',
          ),
          MonthlyBillEntity(
            id: 'bill_oct_cholas',
            monthKey: '2026-10',
            title: 'Cholas',
            categoryId: 'cat_personal',
            amountMinor: 2000000, // $ 20.000
            isPaid: true,
            dueDateLabel: 'Vence 06/10',
            note: 'Calzado',
          ),
          MonthlyBillEntity(
            id: 'bill_oct_gemini_icloud',
            monthKey: '2026-10',
            title: 'Gemini y iCloud',
            categoryId: 'cat_suscripciones',
            amountMinor: 1350000, // $ 13.500
            isPaid: false,
            dueDateLabel: 'Vence 20/10',
            note: '8.500 + 5.000',
          ),
          MonthlyBillEntity(
            id: 'bill_oct_gas',
            monthKey: '2026-10',
            title: 'Gas',
            categoryId: 'cat_hogar',
            amountMinor: 992300, // $ 9.923
            isPaid: false,
            dueDateLabel: 'Vence 22/10',
            note: 'Factura gas natural',
          ),

          // ==================== SEPTIEMBRE 2026 ====================
          MonthlyBillEntity(
            id: 'bill_sep_alquiler',
            monthKey: '2026-09',
            title: 'Alquiler',
            categoryId: 'cat_hogar',
            amountMinor: 78000000, // $ 780.000
            paidAmountMinor: 30000000, // Pagó $ 300.000
            isPaid: false,
            dueDateLabel: 'Vence 05/09',
            note: 'pague 300.000 (faltan 480.000)',
          ),
          MonthlyBillEntity(
            id: 'bill_sep_jardin',
            monthKey: '2026-09',
            title: 'Inscripción Jardín',
            categoryId: 'cat_colegio',
            amountMinor: 20000000, // $ 200.000
            isPaid: true,
            dueDateLabel: 'Vence 05/09',
            note: 'Matrícula anual jardín',
          ),
          MonthlyBillEntity(
            id: 'bill_sep_colegio',
            monthKey: '2026-09',
            title: 'Colegio',
            categoryId: 'cat_colegio',
            amountMinor: 17707200, // $ 177.072
            isPaid: true,
            dueDateLabel: 'Vence 10/09',
            note: 'Cuota septiembre',
          ),
          MonthlyBillEntity(
            id: 'bill_sep_luz_marina',
            monthKey: '2026-09',
            title: 'Luz Marina',
            categoryId: 'cat_emilis',
            amountMinor: 12000000, // $ 120.000
            isPaid: true,
            dueDateLabel: 'Vence 10/09',
            note: '20.000 + 100.000',
          ),
          MonthlyBillEntity(
            id: 'bill_sep_seguro_auto',
            monthKey: '2026-09',
            title: 'Seguro Auto',
            categoryId: 'cat_auto_transporte',
            amountMinor: 10605900, // $ 106.059
            isPaid: true,
            dueDateLabel: 'Vence 15/09',
            note: 'Lo gasté en nafta y pastillas de freno',
          ),
          MonthlyBillEntity(
            id: 'bill_sep_papa',
            monthKey: '2026-09',
            title: 'Papá',
            categoryId: 'cat_emilis',
            amountMinor: 8000000, // $ 80.000
            isPaid: true,
            dueDateLabel: 'Vence 12/09',
            note: 'Ayuda familiar',
          ),
          MonthlyBillEntity(
            id: 'bill_sep_gocuotas',
            monthKey: '2026-09',
            title: 'Go Cuotas',
            categoryId: 'cat_cuotas',
            amountMinor: 5521700, // $ 55.217
            isPaid: true,
            dueDateLabel: 'Vence 10/09',
          ),
          MonthlyBillEntity(
            id: 'bill_sep_mp',
            monthKey: '2026-09',
            title: 'Mercado Pago',
            categoryId: 'cat_cuotas',
            amountMinor: 4878100, // $ 48.781
            isPaid: true,
            dueDateLabel: 'Vence 08/09',
          ),
          MonthlyBillEntity(
            id: 'bill_sep_luz',
            monthKey: '2026-09',
            title: 'Luz',
            categoryId: 'cat_hogar',
            amountMinor: 3374900, // $ 33.749
            isPaid: true,
            dueDateLabel: 'Vence 12/09',
          ),
          MonthlyBillEntity(
            id: 'bill_sep_internet',
            monthKey: '2026-09',
            title: 'Internet',
            categoryId: 'cat_hogar',
            amountMinor: 2695500, // $ 26.955
            isPaid: true,
            dueDateLabel: 'Vence 15/09',
          ),
          MonthlyBillEntity(
            id: 'bill_sep_gas',
            monthKey: '2026-09',
            title: 'Gas',
            categoryId: 'cat_hogar',
            amountMinor: 989900, // $ 9.899
            isPaid: true,
            dueDateLabel: 'Vence 20/09',
          ),
          MonthlyBillEntity(
            id: 'bill_sep_gemini',
            monthKey: '2026-09',
            title: 'Gemini y iCloud',
            categoryId: 'cat_suscripciones',
            amountMinor: 770000, // $ 7.700
            isPaid: true,
            dueDateLabel: 'Vence 20/09',
          ),

          // ==================== AGOSTO 2026 ====================
          MonthlyBillEntity(
            id: 'bill_aug_alquiler',
            monthKey: '2026-08',
            title: 'Alquiler',
            categoryId: 'cat_hogar',
            amountMinor: 78000000, // $ 780.000
            isPaid: true,
            dueDateLabel: 'Vence 05/08',
          ),
          MonthlyBillEntity(
            id: 'bill_aug_mecanico',
            monthKey: '2026-08',
            title: 'Mecánico',
            categoryId: 'cat_auto_transporte',
            amountMinor: 60000000, // $ 600.000
            isPaid: true,
            dueDateLabel: 'Vence 10/08',
            note: 'Arreglo general auto',
          ),
          MonthlyBillEntity(
            id: 'bill_aug_fiat',
            monthKey: '2026-08',
            title: 'Transferencia Fiat',
            categoryId: 'cat_auto_transporte',
            amountMinor: 20000000, // $ 200.000
            isPaid: true,
            dueDateLabel: 'Vence 08/08',
          ),
          MonthlyBillEntity(
            id: 'bill_aug_colegio',
            monthKey: '2026-08',
            title: 'Colegio',
            categoryId: 'cat_colegio',
            amountMinor: 17331000, // $ 173.310
            isPaid: true,
            dueDateLabel: 'Vence 10/08',
          ),
          MonthlyBillEntity(
            id: 'bill_aug_luz_marina',
            monthKey: '2026-08',
            title: 'Luz Marina',
            categoryId: 'cat_emilis',
            amountMinor: 15000000, // $ 150.000
            isPaid: true,
            dueDateLabel: 'Vence 10/08',
          ),
          MonthlyBillEntity(
            id: 'bill_aug_mp',
            monthKey: '2026-08',
            title: 'Mercado Pago',
            categoryId: 'cat_cuotas',
            amountMinor: 4827700, // $ 48.277
            isPaid: true,
            dueDateLabel: 'Vence 08/08',
          ),
          MonthlyBillEntity(
            id: 'bill_aug_internet',
            monthKey: '2026-08',
            title: 'Internet',
            categoryId: 'cat_hogar',
            amountMinor: 4081900, // $ 40.819
            isPaid: true,
            dueDateLabel: 'Vence 15/08',
          ),
          MonthlyBillEntity(
            id: 'bill_aug_luz',
            monthKey: '2026-08',
            title: 'Luz',
            categoryId: 'cat_hogar',
            amountMinor: 3352100, // $ 33.521
            isPaid: true,
            dueDateLabel: 'Vence 12/08',
          ),
          MonthlyBillEntity(
            id: 'bill_aug_emilis',
            monthKey: '2026-08',
            title: 'Emilis (Fijo)',
            categoryId: 'cat_emilis',
            amountMinor: 3000000, // $ 30.000
            isPaid: true,
            dueDateLabel: 'Vence 05/08',
          ),
          MonthlyBillEntity(
            id: 'bill_aug_gocuotas',
            monthKey: '2026-08',
            title: 'Go Cuotas',
            categoryId: 'cat_cuotas',
            amountMinor: 2937000, // $ 29.370
            isPaid: true,
            dueDateLabel: 'Vence 10/08',
          ),
          MonthlyBillEntity(
            id: 'bill_aug_gas',
            monthKey: '2026-08',
            title: 'Gas',
            categoryId: 'cat_hogar',
            amountMinor: 995700, // $ 9.957
            isPaid: true,
            dueDateLabel: 'Vence 20/08',
          ),
        ]);

  void toggleBillPaid(String billId) {
    state = [
      for (final b in state)
        if (b.id == billId) b.copyWith(isPaid: !b.isPaid) else b,
    ];
  }

  /// Permite modificar absolutamente todos los datos de un Gasto Fijo existente.
  void updateBillFull({
    required String billId,
    required String title,
    required String categoryId,
    required int amountMinor,
    int? paidAmountMinor,
    required String dueDateLabel,
    required String note,
    bool? isPaid,
  }) {
    state = [
      for (final b in state)
        if (b.id == billId)
          b.copyWith(
            title: title,
            categoryId: categoryId,
            amountMinor: amountMinor,
            paidAmountMinor: paidAmountMinor,
            clearPaidAmount: paidAmountMinor == null || paidAmountMinor <= 0,
            dueDateLabel: dueDateLabel,
            note: note,
            isPaid: isPaid ?? b.isPaid,
          )
        else
          b,
    ];
  }

  void deleteBill(String billId) {
    state = [
      for (final b in state)
        if (b.id != billId) b,
    ];
  }

  void addBill({
    required String monthKey,
    required String title,
    required int amountMinor,
    required String dueDateLabel,
    required String note,
    String categoryId = 'cat_hogar',
    bool isPaid = false,
  }) {
    state = [
      MonthlyBillEntity(
        id: 'bill_${DateTime.now().microsecondsSinceEpoch}',
        monthKey: monthKey,
        title: title,
        categoryId: categoryId,
        amountMinor: amountMinor,
        isPaid: isPaid,
        dueDateLabel: dueDateLabel,
        note: note,
      ),
      ...state,
    ];
  }

  /// Copia todos los Gastos Fijos de un mes origen (`sourceMonthKey`) hacia el mes destino
  /// (`targetMonthKey`, ej: '2026-11') como pendientes de pago (`isPaid: false`, `paidAmountMinor: null`),
  /// evitando duplicar aquellos que ya existan con el mismo título en el mes destino.
  int copyFixedBillsFromMonth({
    required String sourceMonthKey,
    required String targetMonthKey,
  }) {
    final sourceBills =
        state.where((b) => b.monthKey == sourceMonthKey).toList();
    final existingTitlesInTarget = state
        .where((b) => b.monthKey == targetMonthKey)
        .map((b) => b.title.toLowerCase().trim())
        .toSet();

    final List<MonthlyBillEntity> copied = [];
    int counter = 0;
    for (final src in sourceBills) {
      if (existingTitlesInTarget.contains(src.title.toLowerCase().trim())) {
        continue;
      }
      counter++;
      copied.add(
        MonthlyBillEntity(
          id: 'bill_${targetMonthKey}_copy_$counter',
          monthKey: targetMonthKey,
          title: src.title,
          categoryId: src.categoryId,
          amountMinor: src.amountMinor,
          paidAmountMinor: null,
          isPaid: false,
          dueDateLabel: src.dueDateLabel,
          note: src.note,
        ),
      );
    }

    if (copied.isNotEmpty) {
      state = [...copied, ...state];
    }
    return copied.length;
  }
}

/// Proveedor de Metas de Ahorro.
final savingsGoalsProvider =
    StateNotifierProvider<SavingsGoalsNotifier, List<SavingsGoalEntity>>((ref) {
  return SavingsGoalsNotifier();
});

class SavingsGoalsNotifier extends StateNotifier<List<SavingsGoalEntity>> {
  SavingsGoalsNotifier()
      : super(const [
          SavingsGoalEntity(
            id: 'goal_emergency',
            name: 'Colchón Fin de Mes (No quedarse corto el día 18)',
            currencyCode: 'ARS',
            targetAmountMinor: 35000000, // $ 350.000 ARS
            currentAmountMinor: 12000000, // $ 120.000 ARS
            linkedAccountId: 'acc_mp_ars',
            icon: Icons.shield_rounded,
            color: Color(0xFF0D7A5F),
            targetDateLabel: 'Meta Mensual',
          ),
          SavingsGoalEntity(
            id: 'goal_usd',
            name: 'Fondo de Emergencia USD',
            currencyCode: 'USD',
            targetAmountMinor: 200000, // US$ 2.000,00
            currentAmountMinor: 145000, // US$ 1.450,00
            linkedAccountId: 'acc_usd_savings',
            icon: Icons.savings_rounded,
            color: Color(0xFF2563EB),
            targetDateLabel: '2027',
          ),
        ]);

  void addContribution(String goalId, int additionalAmountMinor) {
    state = [
      for (final g in state)
        if (g.id == goalId)
          g.copyWith(
            currentAmountMinor: g.currentAmountMinor + additionalAmountMinor,
          )
        else
          g,
    ];
  }

  void createGoal({
    required String name,
    required String currencyCode,
    required int targetAmountMinor,
  }) {
    state = [
      ...state,
      SavingsGoalEntity(
        id: 'goal_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        currencyCode: currencyCode,
        targetAmountMinor: targetAmountMinor,
        currentAmountMinor: 0,
        linkedAccountId:
            currencyCode == 'USD' ? 'acc_usd_savings' : 'acc_mp_ars',
        icon: Icons.flag_rounded,
        color: const Color(0xFF7C3AED),
      ),
    ];
  }
}

/// Proveedor de Reglas Recurrentes (Plantilla base).
final recurringRulesProvider =
    StateNotifierProvider<RecurringRulesNotifier, List<RecurringRuleEntity>>(
        (ref) {
  return RecurringRulesNotifier();
});

class RecurringRulesNotifier extends StateNotifier<List<RecurringRuleEntity>> {
  RecurringRulesNotifier()
      : super(const [
          RecurringRuleEntity(
            id: 'rec_alquiler',
            title: 'Alquiler',
            type: TransactionType.expense,
            accountId: 'acc_bank_ars',
            categoryId: 'cat_hogar',
            amountMinor: 78000000, // $ 780.000 ARS
            currencyCode: 'ARS',
            dayOfMonth: 5,
            rateType: ExchangeRateType.mep,
          ),
          RecurringRuleEntity(
            id: 'rec_colegio',
            title: 'Colegio',
            type: TransactionType.expense,
            accountId: 'acc_bank_ars',
            categoryId: 'cat_colegio',
            amountMinor: 17707200, // $ 177.072 ARS
            currencyCode: 'ARS',
            dayOfMonth: 10,
            rateType: ExchangeRateType.mep,
          ),
          RecurringRuleEntity(
            id: 'rec_sueldo',
            title: 'Sueldo Neto (sin adelanto)',
            type: TransactionType.income,
            accountId: 'acc_bank_ars',
            categoryId: 'cat_sueldo',
            amountMinor: 176747400, // $ 1.767.474 ARS
            currencyCode: 'ARS',
            dayOfMonth: 1,
            rateType: ExchangeRateType.mep,
          ),
          RecurringRuleEntity(
            id: 'rec_adelanto',
            title: 'Adelanto de Sueldo',
            type: TransactionType.income,
            accountId: 'acc_bank_ars',
            categoryId: 'cat_adelanto',
            amountMinor: 70000000, // $ 700.000 ARS
            currencyCode: 'ARS',
            dayOfMonth: 13,
            rateType: ExchangeRateType.mep,
          ),
        ]);
}

/// Lista reactiva de transacciones precargada con tus movimientos reales de
/// Octubre 2026, Septiembre 2026 y Agosto 2026.
final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<TransactionEntity>>((ref) {
  return TransactionsNotifier();
});

class TransactionsNotifier extends StateNotifier<List<TransactionEntity>> {
  TransactionsNotifier()
      : super([
          // ==================== OCTUBRE 2026 ====================
          _tx('oct_inc_1', '2026-10', 'Inicio de Mes', TransactionType.income,
              'acc_bank_ars', 'cat_sueldo', 176747400, 'Sueldo (descontando adelanto de 700.000)'),
          _tx('oct_inc_2', '2026-10', 'Martes 13', TransactionType.income,
              'acc_bank_ars', 'cat_adelanto', 70000000, 'Adelanto de sueldo de 700.000'),
          _tx('oct_15_1', '2026-10', 'Jueves 15', TransactionType.expense,
              'acc_mp_ars', 'cat_super', 902900, 'Fiambre'),
          _tx('oct_15_2', '2026-10', 'Jueves 15', TransactionType.expense,
              'acc_mp_ars', 'cat_auto_transporte', 411000, 'Denuncia de venta Captiva'),
          _tx('oct_15_3', '2026-10', 'Jueves 15', TransactionType.expense,
              'acc_mp_ars', 'cat_auto_transporte', 390000, 'DiDi'),
          _tx('oct_14_1', '2026-10', 'Miércoles 14', TransactionType.expense,
              'acc_mp_ars', 'cat_emilis', 4500000, 'Emilis (25.000 + 20.000)'),
          _tx('oct_12_1', '2026-10', 'Lunes 12', TransactionType.expense,
              'acc_mp_ars', 'cat_super', 740000, 'Jamón y queso'),
          _tx('oct_12_2', '2026-10', 'Lunes 12', TransactionType.expense,
              'acc_mp_ars', 'cat_emilis', 2300000, 'Emilis (5.000 + 18.000)'),
          _tx('oct_11_1', '2026-10', 'Domingo 11', TransactionType.expense,
              'acc_cash_ars', 'cat_super', 470000, 'Chino harina y toallas'),
          _tx('oct_10_1', '2026-10', 'Sábado 10', TransactionType.expense,
              'acc_mp_ars', 'cat_comida', 950000, 'Mostaza'),
          _tx('oct_10_2', '2026-10', 'Sábado 10', TransactionType.expense,
              'acc_mp_ars', 'cat_personal', 3300000, 'Corte de pelo'),
          _tx('oct_10_3', '2026-10', 'Sábado 10', TransactionType.expense,
              'acc_mp_ars', 'cat_emilis', 1400000, 'Emilis'),
          _tx('oct_09_1', '2026-10', 'Viernes 09', TransactionType.expense,
              'acc_mp_ars', 'cat_emilis', 2000000, 'Emilis'),
          _tx('oct_08_1', '2026-10', 'Jueves 08', TransactionType.expense,
              'acc_mp_ars', 'cat_emilis', 470000, 'Emilis (3.700 + 1.000)'),
          _tx('oct_08_2', '2026-10', 'Jueves 08', TransactionType.expense,
              'acc_cash_ars', 'cat_comida', 599000, 'Pancho (4.100 + 1.890)'),
          _tx('oct_07_1', '2026-10', 'Miércoles 07', TransactionType.expense,
              'acc_mp_ars', 'cat_suscripciones', 250000, 'Tuenti Emilis'),
          _tx('oct_07_2', '2026-10', 'Miércoles 07', TransactionType.expense,
              'acc_cash_ars', 'cat_super', 1100000, 'Pollo'),
          _tx('oct_07_3', '2026-10', 'Miércoles 07', TransactionType.expense,
              'acc_mp_ars', 'cat_auto_transporte', 543000, 'SUBE (3.000 + 2.430)'),
          _tx('oct_06_1', '2026-10', 'Martes 06', TransactionType.expense,
              'acc_cash_ars', 'cat_super', 1250000, 'Queso Yuli'),
          _tx('oct_06_2', '2026-10', 'Martes 06', TransactionType.expense,
              'acc_mp_ars', 'cat_personal', 900000, 'Farmacia'),
          _tx('oct_06_3', '2026-10', 'Martes 06', TransactionType.expense,
              'acc_mp_ars', 'cat_comida', 1380000, 'Burger (6.100 + 7.700)'),
          _tx('oct_06_4', '2026-10', 'Martes 06', TransactionType.expense,
              'acc_cash_ars', 'cat_super', 1240000, 'Chino'),
          _tx('oct_06_5', '2026-10', 'Martes 06', TransactionType.expense,
              'acc_mp_ars', 'cat_super', 4510000, 'Carne'),
          _tx('oct_06_6', '2026-10', 'Martes 06', TransactionType.expense,
              'acc_mp_ars', 'cat_super', 1581900, 'Reyes del Oeste'),
          _tx('oct_06_7', '2026-10', 'Martes 06', TransactionType.expense,
              'acc_cash_ars', 'cat_super', 600000, 'Súper Oso'),
          _tx('oct_06_8', '2026-10', 'Martes 06', TransactionType.expense,
              'acc_mp_ars', 'cat_super', 918900, 'Carrefour'),
          _tx('oct_06_9', '2026-10', 'Martes 06', TransactionType.expense,
              'acc_cash_ars', 'cat_super', 3078800, 'Verduras'),

          // ==================== SEPTIEMBRE 2026 ====================
          _tx('sep_inc_1', '2026-09', 'Inicio de Mes', TransactionType.income,
              'acc_bank_ars', 'cat_sueldo', 176559300, 'Sueldo (descontando adelanto de 700.000)'),
          _tx('sep_inc_2', '2026-09', 'Jueves 10', TransactionType.income,
              'acc_bank_ars', 'cat_adelanto', 70000000, 'Adelanto de sueldo de 700.000'),
          _tx('sep_18_1', '2026-09', 'Viernes 18', TransactionType.expense,
              'acc_cash_ars', 'cat_super', 1600000, 'Fiambre (Después de esta fecha me quedé sin plata)'),
          _tx('sep_17_1', '2026-09', 'Jueves 17', TransactionType.expense,
              'acc_cash_ars', 'cat_super', 2740000, 'Pollo y verdura (11.700 + 4.700) + Panadería (11.000)'),
          _tx('sep_16_1', '2026-09', 'Miércoles 16', TransactionType.expense,
              'acc_bank_ars', 'cat_emilis', 31000000, 'Pasaporte Papá'),
          _tx('sep_16_2', '2026-09', 'Miércoles 16', TransactionType.expense,
              'acc_mp_ars', 'cat_super', 2648000, 'Carnicería y ramen (16.500) + Día y chorizo (9.980)'),
          _tx('sep_15_1', '2026-09', 'Martes 15', TransactionType.expense,
              'acc_mp_ars', 'cat_personal', 5300000, 'Uñas (13.500) + Harina/crema (16.000) + Tinte (5.000) + Chino/farmacia (18.500)'),
          _tx('sep_14_1', '2026-09', 'Lunes 14', TransactionType.expense,
              'acc_mp_ars', 'cat_auto_transporte', 5633100, 'Frenos (32.400 + 14.000) + Uber (3.731 + 2.600 + 3.600)'),
          _tx('sep_12_1', '2026-09', 'Sábado 12', TransactionType.expense,
              'acc_mp_ars', 'cat_super', 11299000, 'Reyes del Oeste (36.500) + Hamburguesa (39.000) + Desayuno/Limpieza/Regalo'),
          _tx('sep_07_1', '2026-09', 'Lunes 07', TransactionType.expense,
              'acc_mp_ars', 'cat_comida', 11399500, 'Parque (45.000) + McDonald\'s (34.000) + YPF y peaje (17.385) + Pizza'),
          _tx('sep_06_1', '2026-09', 'Domingo 06', TransactionType.expense,
              'acc_mp_ars', 'cat_super', 10525000, 'Carrefour (57.000) + Verdulería (28.650) + Panadería/Bazar/Easy'),
          _tx('sep_05_1', '2026-09', 'Sábado 05', TransactionType.expense,
              'acc_mp_ars', 'cat_super', 14577100, 'Don Ángel (80.592) + Vital (44.479) + Burger/Molly/Verdura'),

          // ==================== AGOSTO 2026 ====================
          _tx('aug_inc_1', '2026-08', 'Inicio de Mes', TransactionType.income,
              'acc_bank_ars', 'cat_sueldo', 256900000, 'Sueldo Agosto completo'),
          _tx('aug_15_1', '2026-08', 'Sábado 15', TransactionType.expense,
              'acc_mp_ars', 'cat_auto_transporte', 13016600, 'Repuesto manguera (40.000) + Monopatín (28.000) + Reyes (22.366) + Nafta/Burger'),
          _tx('aug_13_1', '2026-08', 'Jueves 13', TransactionType.expense,
              'acc_bank_ars', 'cat_auto_transporte', 31489600, 'Mecánico (250.000) + Papá (30.000) + Nafta/Uber/Fiambre'),
          _tx('aug_09_1', '2026-08', 'Domingo 09', TransactionType.expense,
              'acc_mp_ars', 'cat_super', 6596800, 'Carrefour (44.208) + Verduras y huevo (15.400) + Pan (6.360)'),
          _tx('aug_08_1', '2026-08', 'Sábado 08', TransactionType.expense,
              'acc_mp_ars', 'cat_super', 26115500, 'Don Ángel (158.900) + Gasolina y aceite (40.000) + Pañales (26.155) + Mostaza/Química'),
        ]);

  static TransactionEntity _tx(
    String id,
    String monthKey,
    String dayLabel,
    TransactionType type,
    String accountId,
    String categoryId,
    int amountMinor,
    String note,
  ) {
    return TransactionEntity(
      id: id,
      monthKey: monthKey,
      dayLabel: dayLabel,
      type: type,
      accountId: accountId,
      categoryId: categoryId,
      amountMinor: amountMinor,
      currencyCode: 'ARS',
      exchangeRateType: ExchangeRateType.oficial,
      exchangeRateToUsd: 1015.0,
      amountUsdMinor: (amountMinor / 1015.0).round(),
      transactionDate: DateTime.now(),
      note: note,
      syncStatus: SyncStatus.synced,
    );
  }

  void addTransaction(TransactionEntity tx) {
    state = [tx, ...state];
  }

  void updateTransaction(TransactionEntity updatedTx) {
    state = [
      for (final tx in state)
        if (tx.id == updatedTx.id) updatedTx else tx,
    ];
  }

  void deleteTransaction(String txId) {
    state = state.where((tx) => tx.id != txId).toList();
  }

  String exportToCsv(
    List<TransactionEntity> items,
    List<AccountEntity> accounts,
    List<CategoryEntity> categories,
  ) {
    final buffer = StringBuffer(
      'Mes,Dia,Tipo,Cuenta,Categoria,Monto Original,Moneda,Cotizacion Oficial Venta,Equivalente USD,Nota\n',
    );
    for (final tx in items) {
      final acc = accounts.where((a) => a.id == tx.accountId).firstOrNull;
      final cat = categories.where((c) => c.id == tx.categoryId).firstOrNull;
      final majorAmount = (tx.amountMinor / 100.0).toStringAsFixed(2);
      final usdMajor = (tx.amountUsdMinor / 100.0).toStringAsFixed(2);
      final safeNote = tx.note.replaceAll(',', ' ');

      buffer.writeln(
        '${tx.monthKey},${tx.dayLabel},${tx.type.label},${acc?.name ?? ''},${cat?.name ?? 'Transferencia'},$majorAmount,${tx.currencyCode},${tx.exchangeRateToUsd},$usdMajor,$safeNote',
      );
    }
    return buffer.toString();
  }
}

/// Estado del formulario de Alta Rápida (<= 3 toques) con soporte de suma ('+').
class QuickTransactionState {
  const QuickTransactionState({
    required this.type,
    required this.rawExpression,
    required this.selectedAccountId,
    this.toAccountId,
    required this.selectedCategoryId,
    required this.rateType,
    required this.customExchangeRate,
    required this.transactionDate,
    this.note = '',
    this.autoSaveOnCategoryTap = false,
  });

  final TransactionType type;
  final String rawExpression;
  final String selectedAccountId;
  final String? toAccountId;
  final String selectedCategoryId;
  final ExchangeRateType rateType;
  final double customExchangeRate;
  final DateTime transactionDate;
  final String note;
  final bool autoSaveOnCategoryTap;

  int get amountMinor {
    if (rawExpression.trim().isEmpty) return 0;
    final parts = rawExpression.split('+');
    int totalMajor = 0;
    for (final p in parts) {
      totalMajor += int.tryParse(p.trim()) ?? 0;
    }
    return totalMajor * 100;
  }

  bool get hasMultiSum => rawExpression.contains('+');

  int calculateUsdMinor(String accountCurrency) {
    if (accountCurrency == 'USD') return amountMinor;
    return MoneyFormatter.convertArsMinorToUsdMinor(
      arsAmountMinor: amountMinor,
      exchangeRateToUsd: customExchangeRate,
    );
  }

  QuickTransactionState copyWith({
    TransactionType? type,
    String? rawExpression,
    String? selectedAccountId,
    String? toAccountId,
    String? selectedCategoryId,
    ExchangeRateType? rateType,
    double? customExchangeRate,
    DateTime? transactionDate,
    String? note,
    bool? autoSaveOnCategoryTap,
  }) {
    return QuickTransactionState(
      type: type ?? this.type,
      rawExpression: rawExpression ?? this.rawExpression,
      selectedAccountId: selectedAccountId ?? this.selectedAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      rateType: rateType ?? this.rateType,
      customExchangeRate: customExchangeRate ?? this.customExchangeRate,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      autoSaveOnCategoryTap:
          autoSaveOnCategoryTap ?? this.autoSaveOnCategoryTap,
    );
  }
}

final quickTransactionControllerProvider = StateNotifierProvider.autoDispose<
    QuickTransactionController, QuickTransactionState>((ref) {
  return QuickTransactionController(ref);
});

class QuickTransactionController extends StateNotifier<QuickTransactionState> {
  QuickTransactionController(this._ref)
      : super(
          QuickTransactionState(
            type: TransactionType.expense,
            rawExpression: '',
            selectedAccountId: 'acc_mp_ars',
            toAccountId: 'acc_usd_savings',
            selectedCategoryId: 'cat_super',
            rateType: ExchangeRateType.oficial,
            customExchangeRate: _ref
                .read(liveExchangeRatesProvider)
                .rateFor(ExchangeRateType.oficial),
            transactionDate: DateTime.now(),
          ),
        );

  final Ref _ref;

  void setTransactionType(TransactionType newType) {
    final categories = _ref.read(categoriesProvider);
    final firstMatchingCategory = categories
        .where((c) => c.kind == newType)
        .map((c) => c.id)
        .firstOrNull;

    state = state.copyWith(
      type: newType,
      selectedCategoryId: firstMatchingCategory ?? state.selectedCategoryId,
    );
  }

  void appendDigit(String digit) {
    if (state.rawExpression.length >= 24) return;
    if (digit == '+') {
      if (state.rawExpression.isEmpty || state.rawExpression.endsWith('+')) {
        return;
      }
      state = state.copyWith(rawExpression: '${state.rawExpression}+');
      return;
    }
    if (state.rawExpression.isEmpty && (digit == '0' || digit == '000')) return;
    state = state.copyWith(rawExpression: '${state.rawExpression}$digit');
  }

  void backspace() {
    if (state.rawExpression.isEmpty) return;
    state = state.copyWith(
      rawExpression:
          state.rawExpression.substring(0, state.rawExpression.length - 1),
    );
  }

  void clearAmount() {
    state = state.copyWith(rawExpression: '');
  }

  void selectAccount(String accountId) {
    state = state.copyWith(selectedAccountId: accountId);
  }

  void selectDestinationAccount(String toAccountId) {
    state = state.copyWith(toAccountId: toAccountId);
  }

  void selectCategory(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  void selectExchangeRateType(ExchangeRateType type) {
    final liveRates = _ref.read(liveExchangeRatesProvider);
    state = state.copyWith(
      rateType: type,
      customExchangeRate: liveRates.rateFor(type),
    );
  }

  void updateNote(String note) {
    state = state.copyWith(note: note);
  }

  void toggleAutoSaveOnCategoryTap(bool value) {
    state = state.copyWith(autoSaveOnCategoryTap: value);
  }

  bool submitTransaction() {
    if (state.amountMinor <= 0) return false;

    final accounts = _ref.read(accountsProvider);
    final selectedMonth = _ref.read(selectedMonthProvider);
    final originAccount = accounts.firstWhere(
      (a) => a.id == state.selectedAccountId,
      orElse: () => accounts.first,
    );

    final usdMinor = state.calculateUsdMinor(originAccount.currencyCode);

    int? creditedMinor;
    if (state.type == TransactionType.transfer && state.toAccountId != null) {
      final destAccount = accounts.firstWhere(
        (a) => a.id == state.toAccountId,
        orElse: () => accounts.last,
      );
      if (originAccount.currencyCode == destAccount.currencyCode) {
        creditedMinor = state.amountMinor;
      } else if (originAccount.currencyCode == 'ARS' &&
          destAccount.currencyCode == 'USD') {
        creditedMinor = usdMinor;
      } else {
        creditedMinor = MoneyFormatter.convertUsdMinorToArsMinor(
          usdAmountMinor: state.amountMinor,
          exchangeRateToUsd: state.customExchangeRate,
        );
      }
    }

    // Si usó suma rápida (ej: 6100+7700), anexamos el desglose a la nota
    final String finalNote = state.hasMultiSum
        ? '${state.note.trim().isEmpty ? 'Suma' : state.note.trim()} (${state.rawExpression.replaceAll('+', ' + ')})'
        : state.note.trim();

    final newTx = TransactionEntity(
      id: 'tx_${DateTime.now().microsecondsSinceEpoch}',
      monthKey: selectedMonth.key,
      dayLabel: 'Hoy',
      type: state.type,
      accountId: originAccount.id,
      toAccountId:
          state.type == TransactionType.transfer ? state.toAccountId : null,
      categoryId: state.type == TransactionType.transfer
          ? null
          : state.selectedCategoryId,
      amountMinor: state.amountMinor,
      currencyCode: originAccount.currencyCode,
      toAmountMinor: creditedMinor,
      exchangeRateType: state.rateType,
      exchangeRateToUsd: state.customExchangeRate,
      amountUsdMinor: usdMinor,
      transactionDate: state.transactionDate,
      note: finalNote,
      syncStatus: SyncStatus.pendingPush,
    );

    _ref.read(transactionsProvider.notifier).addTransaction(newTx);
    _ref.read(accountsProvider.notifier).applyTransaction(newTx);
    return true;
  }
}
