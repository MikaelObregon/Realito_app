import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/transactions/domain/entities/transaction_models.dart';

/// Cotizaciones actualizadas de Argentina usando exclusivamente el Precio de Venta,
/// con Dólar Oficial como referencia principal.
class LiveExchangeRates {
  const LiveExchangeRates({
    required this.sellRatesByType,
    required this.updatedAt,
    required this.isFromLiveApi,
  });

  final Map<ExchangeRateType, double> sellRatesByType;
  final DateTime updatedAt;
  final bool isFromLiveApi;

  /// Devuelve el Precio de Venta para el tipo de cambio indicado.
  double rateFor(ExchangeRateType type) =>
      sellRatesByType[type] ?? type.defaultSellRate;
}

/// Servicio que consulta el Precio de Venta del Dólar Oficial en DolarApi.com
/// con fallback Offline-First inmediato.
class ExchangeRateService {
  static const String _endpoint = 'https://dolarapi.com/v1/dolares';

  Future<LiveExchangeRates> fetchArgentinaRates() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 4);

    final Map<ExchangeRateType, double> defaults = {
      for (final t in ExchangeRateType.values) t: t.defaultSellRate,
    };

    try {
      final request = await client.getUrl(Uri.parse(_endpoint));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final List<dynamic> decoded = jsonDecode(body) as List<dynamic>;

        final map = Map<ExchangeRateType, double>.from(defaults);

        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final casa = (item['casa'] as String?)?.toLowerCase() ?? '';
            final venta = (item['venta'] as num?)?.toDouble();
            if (venta == null || venta <= 0) continue;

            if (casa == 'oficial') {
              map[ExchangeRateType.oficial] = venta;
            } else if (casa == 'bolsa') {
              map[ExchangeRateType.mep] = venta;
            } else if (casa == 'blue') {
              map[ExchangeRateType.blue] = venta;
            } else if (casa == 'tarjeta') {
              map[ExchangeRateType.tarjeta] = venta;
            }
          }
        }

        return LiveExchangeRates(
          sellRatesByType: map,
          updatedAt: DateTime.now(),
          isFromLiveApi: true,
        );
      }
    } catch (_) {
      // Fallback Offline-First
    } finally {
      client.close();
    }

    return LiveExchangeRates(
      sellRatesByType: defaults,
      updatedAt: DateTime.now(),
      isFromLiveApi: false,
    );
  }
}

final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});

final liveExchangeRatesProvider =
    StateNotifierProvider<LiveExchangeRatesNotifier, LiveExchangeRates>((ref) {
  final service = ref.watch(exchangeRateServiceProvider);
  return LiveExchangeRatesNotifier(service);
});

class LiveExchangeRatesNotifier extends StateNotifier<LiveExchangeRates> {
  LiveExchangeRatesNotifier(this._service)
      : super(
          LiveExchangeRates(
            sellRatesByType: {
              for (final t in ExchangeRateType.values) t: t.defaultSellRate,
            },
            updatedAt: DateTime.now(),
            isFromLiveApi: false,
          ),
        ) {
    refreshRates();
  }

  final ExchangeRateService _service;

  Future<void> refreshRates() async {
    final latest = await _service.fetchArgentinaRates();
    if (mounted) {
      state = latest;
    }
  }
}
