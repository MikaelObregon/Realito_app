import 'package:intl/intl.dart';

/// Utilidad para formatear y convertir montos expresados en unidades menores (centavos)
/// evitando errores de redondeo de punto flotante (IEEE 754).
abstract final class MoneyFormatter {
  static final NumberFormat _arsFormat = NumberFormat.currency(
    locale: 'es_AR',
    symbol: r'$ ',
    decimalDigits: 0, // En Argentina el uso cotidiano suele omitir centavos si son .00
  );

  static final NumberFormat _arsWithCentsFormat = NumberFormat.currency(
    locale: 'es_AR',
    symbol: r'$ ',
    decimalDigits: 2,
  );

  static final NumberFormat _usdFormat = NumberFormat.currency(
    locale: 'es_AR',
    symbol: 'US\$ ',
    decimalDigits: 2,
  );

  /// Formatea un monto en centavos (`amountMinor`) según el código de moneda (`ARS` o `USD`).
  static String formatMinor(
    int amountMinor, {
    required String currencyCode,
    bool forceDecimals = false,
  }) {
    final double majorValue = amountMinor / 100.0;
    if (currencyCode.toUpperCase() == 'USD') {
      return _usdFormat.format(majorValue);
    }
    final bool hasCents = (amountMinor % 100) != 0;
    if (forceDecimals || hasCents) {
      return _arsWithCentsFormat.format(majorValue);
    }
    return _arsFormat.format(majorValue);
  }

  /// Calcula el equivalente en centavos de USD a partir de un monto en centavos de ARS
  /// y una cotización histórica (ej: 1210.50 ARS por 1 USD).
  static int convertArsMinorToUsdMinor({
    required int arsAmountMinor,
    required double exchangeRateToUsd,
  }) {
    if (exchangeRateToUsd <= 0) return 0;
    return (arsAmountMinor / exchangeRateToUsd).round();
  }

  /// Calcula el equivalente en centavos de ARS a partir de un monto en centavos de USD.
  static int convertUsdMinorToArsMinor({
    required int usdAmountMinor,
    required double exchangeRateToUsd,
  }) {
    if (exchangeRateToUsd <= 0) return 0;
    return (usdAmountMinor * exchangeRateToUsd).round();
  }

  /// Evalúa una expresión numérica o suma rápida con `+` (ej: "30.788" -> 3078800 centavos,
  /// "20000+13000" -> 3300000 centavos, "7000+200000+30000+20000" -> 25700000 centavos).
  static int evaluateSumExpressionToMinor(String rawExpression) {
    final cleaned = rawExpression.trim();
    if (cleaned.isEmpty) return 0;
    final parts = cleaned.split('+');
    int totalMajor = 0;
    for (final part in parts) {
      final digitsOnly = part.replaceAll('.', '').replaceAll(',', '').trim();
      if (digitsOnly.isNotEmpty) {
        totalMajor += int.tryParse(digitsOnly) ?? 0;
      }
    }
    return totalMajor * 100;
  }

  /// Calcula el Saldo Disponible Real del mes en centavos:
  /// Disponible = Ingresos - Total Gastos Fijos Comprometidos - Gastos Diarios
  static int calculateAvailableMonthMinor({
    required int totalIncomeMinor,
    required int totalFixedBillsMinor,
    required int totalDailyExpensesMinor,
  }) {
    return totalIncomeMinor - totalFixedBillsMinor - totalDailyExpensesMinor;
  }

  /// Calcula los días restantes reales hasta la próxima fecha de cobro (`nextPaydayDate`).
  /// Nunca devuelve menos de 1 día para evitar división por cero.
  static int computeDaysUntilNextPayday({
    required DateTime currentDate,
    required DateTime nextPaydayDate,
  }) {
    final start = DateTime(currentDate.year, currentDate.month, currentDate.day);
    final end = DateTime(nextPaydayDate.year, nextPaydayDate.month, nextPaydayDate.day);
    final diffDays = end.difference(start).inDays;
    return diffDays < 1 ? 1 : diffDays;
  }

  /// Determina si un mes permite transferir su saldo positivo a favor al mes siguiente:
  /// Regla de negocio:
  /// 1) El saldo disponible debe ser estrictamente positivo (`availableMinor > 0`).
  ///    Si cerró en negativo (ej. Septiembre), jamás se arrastra deuda.
  /// 2) Debe ser un mes cerrado anterior o el último día del mes en curso.
  /// 3) No debe haberse transferido previamente (`!alreadyTransferred`).
  static bool canTransferMonthSurplus({
    required int availableMinor,
    required bool isClosedPastMonth,
    required bool isLastDayOfCurrentMonth,
    required bool alreadyTransferred,
  }) {
    if (availableMinor <= 0) return false;
    if (alreadyTransferred) return false;
    return isClosedPastMonth || isLastDayOfCurrentMonth;
  }
}

