import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realito_app/features/transactions/domain/entities/transaction_models.dart';
import 'package:realito_app/features/transactions/presentation/controllers/quick_transaction_controller.dart';

void main() {
  group('Suite 5 — Movimientos Diarios e Ingresos (Alta, Edición, Eliminación y Reversión de Saldos)', () {
    test('TC-20: Al registrar un Gasto Diario descuenta automáticamente el saldo de la cuenta elegida', () {
      final accountsNotifier = AccountsNotifier();
      final txNotifier = TransactionsNotifier();

      final initialPersonalPay = accountsNotifier.state
          .firstWhere((a) => a.id == 'acc_mp_ars')
          .balanceMinor;

      final expenseTx = TransactionEntity(
        id: 'tx_test_gasto_1',
        monthKey: '2026-10',
        dayLabel: 'Hoy',
        type: TransactionType.expense,
        accountId: 'acc_mp_ars',
        categoryId: 'cat_super',
        amountMinor: 1500000, // $ 15.000 ARS
        currencyCode: 'ARS',
        exchangeRateType: ExchangeRateType.oficial,
        exchangeRateToUsd: 1015.0,
        amountUsdMinor: 1478,
        transactionDate: DateTime(2026, 10, 20),
        note: 'Carnicería',
      );

      txNotifier.addTransaction(expenseTx);
      accountsNotifier.applyTransaction(expenseTx);

      final updatedPersonalPay = accountsNotifier.state
          .firstWhere((a) => a.id == 'acc_mp_ars')
          .balanceMinor;
      expect(updatedPersonalPay, initialPersonalPay - 1500000);
    });

    test('TC-21: Al editar un movimiento (cambiando monto y cuenta), revierte el saldo viejo y aplica el nuevo', () {
      final accountsNotifier = AccountsNotifier();
      final txNotifier = TransactionsNotifier();

      final origMp = accountsNotifier.state
          .firstWhere((a) => a.id == 'acc_mp_ars')
          .balanceMinor;
      final origCash = accountsNotifier.state
          .firstWhere((a) => a.id == 'acc_cash_ars')
          .balanceMinor;

      final originalTx = TransactionEntity(
        id: 'tx_edit_flow',
        monthKey: '2026-10',
        dayLabel: 'Ayer',
        type: TransactionType.expense,
        accountId: 'acc_mp_ars',
        categoryId: 'cat_super',
        amountMinor: 1000000, // $ 10.000 en Personal Pay
        currencyCode: 'ARS',
        exchangeRateType: ExchangeRateType.oficial,
        exchangeRateToUsd: 1015.0,
        amountUsdMinor: 985,
        transactionDate: DateTime(2026, 10, 19),
        note: 'Verdulería',
      );

      txNotifier.addTransaction(originalTx);
      accountsNotifier.applyTransaction(originalTx);

      // Ahora editamos: pasó de $ 10.000 en Personal Pay a $ 14.500 en Efectivo ARS
      accountsNotifier.revertTransaction(originalTx);
      final editedTx = TransactionEntity(
        id: 'tx_edit_flow',
        monthKey: '2026-10',
        dayLabel: 'Ayer',
        type: TransactionType.expense,
        accountId: 'acc_cash_ars',
        categoryId: 'cat_super',
        amountMinor: 1450000, // $ 14.500 en Efectivo
        currencyCode: 'ARS',
        exchangeRateType: ExchangeRateType.oficial,
        exchangeRateToUsd: 1015.0,
        amountUsdMinor: 1429,
        transactionDate: DateTime(2026, 10, 19),
        note: 'Verdulería + Frutas',
      );
      txNotifier.updateTransaction(editedTx);
      accountsNotifier.applyTransaction(editedTx);

      // Personal Pay debe haber recuperado su saldo original intacto
      final afterMp = accountsNotifier.state
          .firstWhere((a) => a.id == 'acc_mp_ars')
          .balanceMinor;
      // Efectivo debe haber disminuido $ 14.500
      final afterCash = accountsNotifier.state
          .firstWhere((a) => a.id == 'acc_cash_ars')
          .balanceMinor;

      expect(afterMp, origMp);
      expect(afterCash, origCash - 1450000);
    });

    test('TC-22: Al eliminar un movimiento, restaura el saldo de la billetera y lo quita del historial', () {
      final accountsNotifier = AccountsNotifier();
      final txNotifier = TransactionsNotifier();

      final initialBank = accountsNotifier.state
          .firstWhere((a) => a.id == 'acc_bank_ars')
          .balanceMinor;

      final incomeTx = TransactionEntity(
        id: 'tx_delete_test',
        monthKey: '2026-10',
        dayLabel: 'Hoy',
        type: TransactionType.income,
        accountId: 'acc_bank_ars',
        categoryId: 'cat_uber_didi',
        amountMinor: 2500000, // +$ 25.000
        currencyCode: 'ARS',
        exchangeRateType: ExchangeRateType.oficial,
        exchangeRateToUsd: 1015.0,
        amountUsdMinor: 2463,
        transactionDate: DateTime(2026, 10, 20),
        note: 'Viajes Uber tarde',
      );

      txNotifier.addTransaction(incomeTx);
      accountsNotifier.applyTransaction(incomeTx);
      expect(
        accountsNotifier.state.firstWhere((a) => a.id == 'acc_bank_ars').balanceMinor,
        initialBank + 2500000,
      );

      // Eliminar movimiento
      accountsNotifier.revertTransaction(incomeTx);
      txNotifier.deleteTransaction(incomeTx.id);

      expect(
        accountsNotifier.state.firstWhere((a) => a.id == 'acc_bank_ars').balanceMinor,
        initialBank,
      );
      expect(txNotifier.state.any((t) => t.id == incomeTx.id), isFalse);
    });
  });

  group('Suite 6 — Cuentas / Billeteras, Ajuste de Saldo Real y Transferencias Internas', () {
    test('TC-23: Ajusta manualmente el saldo real de una cuenta ("Ajustar saldo")', () {
      final accountsNotifier = AccountsNotifier();
      accountsNotifier.updateAccount(
        accountId: 'acc_mp_ars',
        name: 'Personal Pay',
        balanceMinor: 52340000, // $ 523.400
      );
      final mp = accountsNotifier.state.firstWhere((a) => a.id == 'acc_mp_ars');
      expect(mp.balanceMinor, 52340000);
    });

    test('TC-24: Transfiere dinero de Banco a Personal Pay descontando origen y sumando destino sin alterar gastos', () {
      final accountsNotifier = AccountsNotifier();
      final beforeBank = accountsNotifier.state
          .firstWhere((a) => a.id == 'acc_bank_ars')
          .balanceMinor;
      final beforeMp = accountsNotifier.state
          .firstWhere((a) => a.id == 'acc_mp_ars')
          .balanceMinor;

      final ok = accountsNotifier.transferBetweenAccounts(
        fromAccountId: 'acc_bank_ars',
        toAccountId: 'acc_mp_ars',
        amountMinor: 10000000, // $ 100.000 ARS
      );
      expect(ok, isTrue);

      final afterBank = accountsNotifier.state
          .firstWhere((a) => a.id == 'acc_bank_ars')
          .balanceMinor;
      final afterMp = accountsNotifier.state
          .firstWhere((a) => a.id == 'acc_mp_ars')
          .balanceMinor;

      expect(afterBank, beforeBank - 10000000);
      expect(afterMp, beforeMp + 10000000);
      // El patrimonio total entre las cuentas se mantiene constante
      expect(afterBank + afterMp, beforeBank + beforeMp);
    });

    test('TC-25: Impide transferir hacia la misma cuenta de origen o con monto cero', () {
      final accountsNotifier = AccountsNotifier();
      expect(
        accountsNotifier.transferBetweenAccounts(
          fromAccountId: 'acc_mp_ars',
          toAccountId: 'acc_mp_ars',
          amountMinor: 500000,
        ),
        isFalse,
      );
      expect(
        accountsNotifier.transferBetweenAccounts(
          fromAccountId: 'acc_bank_ars',
          toAccountId: 'acc_mp_ars',
          amountMinor: 0,
        ),
        isFalse,
      );
    });
  });

  group('Suite 7 — Categorías Separadas (Gastos Fijos, Gastos Diarios, Ingresos) y CRUD con Iconos', () {
    test('TC-26: Las categorías de Gastos Fijos están separadas de las categorías de Gastos Diarios e Ingresos', () {
      final fixedNotifier = FixedBillCategoriesNotifier();
      final dailyAndIncomeNotifier = CategoriesNotifier();

      expect(fixedNotifier.state.isNotEmpty, isTrue);
      expect(
        dailyAndIncomeNotifier.state
            .where((c) => c.kind == TransactionType.expense)
            .isNotEmpty,
        isTrue,
      );
      expect(
        dailyAndIncomeNotifier.state
            .where((c) => c.kind == TransactionType.income)
            .map((c) => c.name),
        containsAll(['Sueldo', 'Adelanto de sueldo', 'Préstamo', 'Uber / DiDi']),
      );
    });

    test('TC-27: Permite crear categoría de Gasto Fijo inline con ícono personalizado, editarla y eliminarla', () {
      final fixedNotifier = FixedBillCategoriesNotifier();
      final initialLen = fixedNotifier.state.length;

      final created = fixedNotifier.addFixedCategory(
        'Cochera / Patente',
        icon: Icons.directions_car_rounded,
      );
      expect(fixedNotifier.state.length, initialLen + 1);
      expect(created.name, 'Cochera / Patente');

      // Editar nombre e ícono
      fixedNotifier.updateFixedCategory(
        created.id,
        name: 'Cochera Mensual',
        icon: Icons.garage_rounded,
      );
      final updated = fixedNotifier.state.firstWhere((c) => c.id == created.id);
      expect(updated.name, 'Cochera Mensual');
      expect(updated.icon, Icons.garage_rounded);

      // Eliminar
      fixedNotifier.deleteFixedCategory(created.id);
      expect(fixedNotifier.state.length, initialLen);
    });
  });
}

