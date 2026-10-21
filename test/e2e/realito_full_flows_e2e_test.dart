import 'package:flutter_test/flutter_test.dart';
import 'package:realito_app/core/utils/money_formatter.dart';
import 'package:realito_app/features/transactions/domain/entities/transaction_models.dart';
import 'package:realito_app/features/transactions/presentation/controllers/quick_transaction_controller.dart';

void main() {
  group('Suite 8 — Prueba End-to-End (E2E) de Todos los Flujos de Realito', () {
    test('TC-28 E2E: Flujo completo mensual desde ingreso de sueldo hasta reporte y traspaso a mes siguiente', () {
      final accounts = AccountsNotifier();
      final fixedBills = MonthlyBillsNotifier();
      final transactions = TransactionsNotifier();
      final categories = CategoriesNotifier();

      // 1. Verificar precarga de Octubre 2026
      final octBills =
          fixedBills.state.where((b) => b.monthKey == '2026-10').toList();
      final octTxs =
          transactions.state.where((t) => t.monthKey == '2026-10').toList();

      final octIncomeMinor = octTxs
          .where((t) => t.type == TransactionType.income)
          .fold<int>(0, (sum, t) => sum + t.amountMinor);
      final octDailyExpensesMinor = octTxs
          .where((t) => t.type == TransactionType.expense)
          .fold<int>(0, (sum, t) => sum + t.amountMinor);
      final octFixedTotalMinor =
          octBills.fold<int>(0, (sum, b) => sum + b.amountMinor);

      expect(octIncomeMinor, 246747400); // $ 2.467.474
      expect(octFixedTotalMinor, 171885500); // $ 1.718.855
      expect(octDailyExpensesMinor, 26861900); // $ 268.619

      // 2. Verificar Saldo Disponible inicial de Octubre ($ 480.000)
      final initialAvailableMinor = MoneyFormatter.calculateAvailableMonthMinor(
        totalIncomeMinor: octIncomeMinor,
        totalFixedBillsMinor: octFixedTotalMinor,
        totalDailyExpensesMinor: octDailyExpensesMinor,
      );
      expect(initialAvailableMinor, 48000000);

      // 3. Cargar nuevo Gasto Diario con suma rápida ("6100+7700" = $ 13.800)
      final sumExpenseMinor =
          MoneyFormatter.evaluateSumExpressionToMinor('6100+7700');
      expect(sumExpenseMinor, 1380000);

      final newExpense = TransactionEntity(
        id: 'e2e_tx_1',
        monthKey: '2026-10',
        dayLabel: 'Hoy',
        type: TransactionType.expense,
        accountId: 'acc_mp_ars',
        categoryId: 'cat_comida',
        amountMinor: sumExpenseMinor,
        currencyCode: 'ARS',
        exchangeRateType: ExchangeRateType.oficial,
        exchangeRateToUsd: 1015.0,
        amountUsdMinor: MoneyFormatter.convertArsMinorToUsdMinor(
          arsAmountMinor: sumExpenseMinor,
          exchangeRateToUsd: 1015.0,
        ),
        transactionDate: DateTime(2026, 10, 20),
        note: 'Cena (6100 + 7700)',
      );
      transactions.addTransaction(newExpense);
      accounts.applyTransaction(newExpense);

      // 4. Verificar que el Saldo Disponible bajó exactamente $ 13.800 -> $ 466.200
      final afterExpenseAvailableMinor =
          MoneyFormatter.calculateAvailableMonthMinor(
        totalIncomeMinor: octIncomeMinor,
        totalFixedBillsMinor: octFixedTotalMinor,
        totalDailyExpensesMinor: octDailyExpensesMinor + sumExpenseMinor,
      );
      expect(afterExpenseAvailableMinor, 46620000);

      // 5. Planificar Noviembre 2026 ⏭️ copiando los 14 gastos fijos de Octubre
      final copiedToNov = fixedBills.copyFixedBillsFromMonth(
        sourceMonthKey: '2026-10',
        targetMonthKey: '2026-11',
      );
      expect(copiedToNov, 14);

      // 6. Exportación / Reporte CSV y verificación de integridad
      final csv = transactions.exportToCsv(
        transactions.state.where((t) => t.monthKey == '2026-10').toList(),
        accounts.state,
        categories.state,
      );
      expect(csv.contains('Cena (6100 + 7700)'), isTrue);
      expect(csv.contains('2026-10'), isTrue);
    });
  });
}

