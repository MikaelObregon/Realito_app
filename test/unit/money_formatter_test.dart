import 'package:flutter_test/flutter_test.dart';
import 'package:realito_app/core/utils/money_formatter.dart';

void main() {
  group('Suite 1 — MoneyFormatter y Calculadora de Suma Rápida (+)', () {
    test('TC-01: Convierte centavos de ARS a centavos de USD según cotización Oficial ($ 1.015)', () {
      // $ 1.015.000 ARS (101500000 centavos) a $ 1.015 = US$ 1.000,00 (100000 centavos)
      final usdMinor = MoneyFormatter.convertArsMinorToUsdMinor(
        arsAmountMinor: 101500000,
        exchangeRateToUsd: 1015.0,
      );
      expect(usdMinor, 100000);
    });

    test('TC-02: Convierte centavos de USD a centavos de ARS sin pérdida de precisión', () {
      // US$ 50,00 (5000 centavos) a $ 1.015 = $ 50.750 ARS (5075000 centavos)
      final arsMinor = MoneyFormatter.convertUsdMinorToArsMinor(
        usdAmountMinor: 5000,
        exchangeRateToUsd: 1015.0,
      );
      expect(arsMinor, 5075000);
    });

    test('TC-03: Maneja cotización cero o negativa devolviendo 0 de forma segura', () {
      expect(
        MoneyFormatter.convertArsMinorToUsdMinor(
          arsAmountMinor: 5000000,
          exchangeRateToUsd: 0,
        ),
        0,
      );
      expect(
        MoneyFormatter.convertUsdMinorToArsMinor(
          usdAmountMinor: 5000,
          exchangeRateToUsd: -100,
        ),
        0,
      );
    });

    test('TC-04: Evalúa monto simple con puntos de miles ("30.788" -> \$ 30.788)', () {
      final minor = MoneyFormatter.evaluateSumExpressionToMinor('30.788');
      expect(minor, 3078800);
    });

    test('TC-05: Evalúa suma rápida de 2 términos ("20000+13000" -> \$ 33.000 Corte de pelo)', () {
      final minor = MoneyFormatter.evaluateSumExpressionToMinor('20000+13000');
      expect(minor, 3300000);
    });

    test('TC-06: Evalúa suma rápida múltiple ("7000+200000+30000+20000" -> \$ 257.000 Luz Marina)', () {
      final minor = MoneyFormatter.evaluateSumExpressionToMinor(
        '7.000 + 200.000 + 30.000 + 20.000',
      );
      expect(minor, 25700000);
    });

    test('TC-07: Formatea montos en ARS sin decimales innecesarios y en USD con 2 decimales', () {
      final formattedArs = MoneyFormatter.formatMinor(
        78000000,
        currencyCode: 'ARS',
      );
      final formattedUsd = MoneyFormatter.formatMinor(
        145000,
        currencyCode: 'USD',
      );
      expect(formattedArs.contains('780.000'), isTrue);
      expect(formattedUsd.contains('1.450,00'), isTrue);
    });
  });
}
