import 'package:flutter_test/flutter_test.dart';
import 'package:realito_app/core/utils/money_formatter.dart';
import 'package:realito_app/features/transactions/domain/entities/transaction_models.dart';
import 'package:realito_app/features/transactions/presentation/controllers/quick_transaction_controller.dart';

void main() {
  group('Suite 2 — Cálculo de Saldo Disponible y Presupuesto Diario hasta Próximo Cobro', () {
    test('TC-08: Calcula Saldo Disponible de Octubre 2026 descontando el total de Gastos Fijos y Gastos Diarios', () {
      // Octubre 2026:
      // Ingresos: $ 1.767.474 + $ 700.000 = $ 2.467.474 (246747400 centavos)
      // Total Gastos Fijos comprometidos: $ 1.718.855 (171885500 centavos)
      // Total Gastos Diarios: $ 268.619 (26861900 centavos)
      // Disponible esperado: $ 480.000 (48000000 centavos)
      final availableMinor = MoneyFormatter.calculateAvailableMonthMinor(
        totalIncomeMinor: 246747400,
        totalFixedBillsMinor: 171885500,
        totalDailyExpensesMinor: 26861900,
      );
      expect(availableMinor, 48000000);
    });

    test('TC-09: Al aumentar un Gasto Fijo (ej. Luz o Alquiler), el Disponible disminuye exactamente en esa diferencia', () {
      final beforeMinor = MoneyFormatter.calculateAvailableMonthMinor(
        totalIncomeMinor: 246747400,
        totalFixedBillsMinor: 171885500,
        totalDailyExpensesMinor: 26861900,
      );
      // Si el alquiler o un servicio sube $ 20.000 (2000000 centavos):
      final afterMinor = MoneyFormatter.calculateAvailableMonthMinor(
        totalIncomeMinor: 246747400,
        totalFixedBillsMinor: 171885500 + 2000000,
        totalDailyExpensesMinor: 26861900,
      );
      expect(beforeMinor - afterMinor, 2000000);
      expect(afterMinor, 46000000);
    });

    test('TC-10: Calcula días reales restantes hasta la fecha configurada de Próximo Cobro', () {
      // Desde el 20/10/2026 hasta el próximo cobro 05/11/2026 hay 16 días reales
      final daysRemaining = MoneyFormatter.computeDaysUntilNextPayday(
        currentDate: DateTime(2026, 10, 20),
        nextPaydayDate: DateTime(2026, 11, 5),
      );
      expect(daysRemaining, 16);

      // Con $ 480.000 disponibles / 16 días = $ 30.000 por día
      final dailyAllowanceMinor = (48000000 / daysRemaining).round();
      expect(dailyAllowanceMinor, 3000000);
    });

    test('TC-11: Nunca divide por cero si la fecha de cobro es hoy o ya pasó (mínimo 1 día)', () {
      final sameDay = MoneyFormatter.computeDaysUntilNextPayday(
        currentDate: DateTime(2026, 11, 5),
        nextPaydayDate: DateTime(2026, 11, 5),
      );
      final pastDay = MoneyFormatter.computeDaysUntilNextPayday(
        currentDate: DateTime(2026, 11, 8),
        nextPaydayDate: DateTime(2026, 11, 5),
      );
      expect(sameDay, 1);
      expect(pastDay, 1);
    });
  });

  group('Suite 3 — Cierre de Mes y Regla de Traspaso de Saldo Positivo', () {
    test('TC-12: Mes cerrado con saldo POSITIVO (Agosto 2026: +\$ 3.635) habilita botón "Pasar al mes siguiente"', () {
      final canTransferAug = MoneyFormatter.canTransferMonthSurplus(
        availableMinor: 363500, // +$ 3.635 ARS
        isClosedPastMonth: true,
        isLastDayOfCurrentMonth: false,
        alreadyTransferred: false,
      );
      expect(canTransferAug, isTrue);
    });

    test('TC-13: Mes cerrado con saldo NEGATIVO (Septiembre 2026: -\$ 167.291) NO arrastra deuda ni muestra botón', () {
      // Septiembre 2026 cerró en -$ 167.291; el mes siguiente arranca limpio de cero
      final canTransferSep = MoneyFormatter.canTransferMonthSurplus(
        availableMinor: -16729100,
        isClosedPastMonth: true,
        isLastDayOfCurrentMonth: false,
        alreadyTransferred: false,
      );
      expect(canTransferSep, isFalse);
    });

    test('TC-14: Mes en curso (Octubre 2026) antes del último día NO muestra traspaso anticipado', () {
      final canTransferMidMonth = MoneyFormatter.canTransferMonthSurplus(
        availableMinor: 48000000,
        isClosedPastMonth: false,
        isLastDayOfCurrentMonth: false,
        alreadyTransferred: false,
      );
      expect(canTransferMidMonth, isFalse);
    });

    test('TC-15: Mes en curso en el último día del mes con saldo positivo SÍ permite pasar sobrante a Noviembre', () {
      final canTransferLastDay = MoneyFormatter.canTransferMonthSurplus(
        availableMinor: 48000000,
        isClosedPastMonth: false,
        isLastDayOfCurrentMonth: true,
        alreadyTransferred: false,
      );
      expect(canTransferLastDay, isTrue);
    });

    test('TC-16: Evita duplicar el traspaso si el saldo de ese mes ya fue transferido', () {
      final canTransferAgain = MoneyFormatter.canTransferMonthSurplus(
        availableMinor: 363500,
        isClosedPastMonth: true,
        isLastDayOfCurrentMonth: false,
        alreadyTransferred: true,
      );
      expect(canTransferAgain, isFalse);
    });
  });

  group('Suite 4 — Gastos Fijos Mensuales, Pagos Parciales y Mes Adelantado (Noviembre 2026 ⏭️)', () {
    test('TC-17: Calcula saldo pendiente exacto en Gasto Fijo con pago parcial (Alquiler Septiembre)', () {
      const billSepAlquiler = MonthlyBillEntity(
        id: 'bill_sep_alquiler',
        monthKey: '2026-09',
        title: 'Alquiler',
        categoryId: 'fcat_vivienda',
        amountMinor: 78000000, // $ 780.000
        paidAmountMinor: 30000000, // Pagado $ 300.000
        isPaid: false,
        dueDateLabel: 'Vence 05/09',
        note: 'pague 300.000 (faltan 480.000)',
      );
      expect(billSepAlquiler.pendingMinor, 48000000); // Faltan $ 480.000
    });

    test('TC-18: Permite crear, editar todos los campos, alternar pagado y eliminar un Gasto Fijo', () {
      final notifier = MonthlyBillsNotifier();
      final initialCount = notifier.state.length;

      notifier.addBill(
        monthKey: '2026-10',
        title: 'Expensas Edificio',
        amountMinor: 6500000,
        dueDateLabel: 'Vence 10/10',
        note: 'Expensas ordinarias',
        categoryId: 'fcat_vivienda',
      );
      expect(notifier.state.length, initialCount + 1);

      final added = notifier.state.first;
      expect(added.title, 'Expensas Edificio');
      expect(added.isPaid, isFalse);

      // Editar monto, pago parcial y nota
      notifier.updateBillFull(
        billId: added.id,
        title: 'Expensas Octubre',
        categoryId: 'fcat_vivienda',
        amountMinor: 7000000,
        paidAmountMinor: 3000000,
        dueDateLabel: 'Vence 12/10',
        note: 'Adelanto expensas',
        isPaid: false,
      );

      final updated = notifier.state.firstWhere((b) => b.id == added.id);
      expect(updated.title, 'Expensas Octubre');
      expect(updated.amountMinor, 7000000);
      expect(updated.pendingMinor, 4000000);

      // Marcar como pagado completo
      notifier.toggleBillPaid(added.id);
      final paidBill = notifier.state.firstWhere((b) => b.id == added.id);
      expect(paidBill.isPaid, isTrue);
      expect(paidBill.pendingMinor, 0);

      // Eliminar gasto fijo
      notifier.deleteBill(added.id);
      expect(notifier.state.length, initialCount);
    });

    test('TC-19: Copia los Gastos Fijos de Octubre 2026 a Noviembre 2026 ⏭️ como pendientes y sin duplicar', () {
      final notifier = MonthlyBillsNotifier();
      final octBillsCount =
          notifier.state.where((b) => b.monthKey == '2026-10').length;
      expect(octBillsCount, 14);

      // Primera copia hacia Noviembre 2026
      final copiedCount = notifier.copyFixedBillsFromMonth(
        sourceMonthKey: '2026-10',
        targetMonthKey: '2026-11',
      );
      expect(copiedCount, 14);

      final novBills =
          notifier.state.where((b) => b.monthKey == '2026-11').toList();
      expect(novBills.length, 14);
      expect(novBills.every((b) => !b.isPaid && b.paidAmountMinor == null), isTrue);

      // Si el usuario vuelve a tocar "Copiar Fijos de Octubre", no duplica los ya existentes
      final secondCopyCount = notifier.copyFixedBillsFromMonth(
        sourceMonthKey: '2026-10',
        targetMonthKey: '2026-11',
      );
      expect(secondCopyCount, 0);
    });
  });
}

