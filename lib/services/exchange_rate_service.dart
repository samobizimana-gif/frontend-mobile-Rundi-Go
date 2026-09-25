import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  ExchangeRateService._private();
  static final ExchangeRateService instance = ExchangeRateService._private();

  double? _cachedBtcToFbu;
  DateTime? _lastFetch;

  double get btcToFbu => _cachedBtcToFbu ?? 124000000.0;
  bool get isLoaded => _cachedBtcToFbu != null;

  /// 👉 Récupère le vrai taux BTC → BIF (Franc burundais)
  /// Source : Coinbase (public, gratuit, pas de clé)
  Future<double> fetchRate() async {
    // 👉 Cache de 5 minutes
    if (_lastFetch != null &&
        DateTime.now().difference(_lastFetch!).inMinutes < 5 &&
        _cachedBtcToFbu != null) {
      return _cachedBtcToFbu!;
    }

    try {
      final res = await http.get(
        Uri.parse('https://api.coinbase.com/v2/exchange-rates?currency=BTC'),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rate = double.tryParse(
            data['data']['rates']['BIF'].toString());
        if (rate != null && rate > 0) {
          _cachedBtcToFbu = rate;
          _lastFetch = DateTime.now();
          return rate;
        }
      }
    } catch (_) {
      // 👉 En cas d'échec, on garde l'ancien taux ou la valeur par défaut
    }

    return _cachedBtcToFbu ?? 124000000.0;
  }
}