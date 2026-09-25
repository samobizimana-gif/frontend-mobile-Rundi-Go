import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/api_client.dart';
import '../core/config.dart';

class BitliberaService {
  BitliberaService._private();
  static final BitliberaService instance = BitliberaService._private();

  double? _cachedRate;

  // ==========================================
  // 📊 TAUX — Coinbase direct (fiable)
  // ==========================================
  Future<double> getRate({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedRate != null) return _cachedRate!;

    // 👉 Valeur par défaut en dur (si Coinbase ne répond pas)
    double rate = 124000000.0;

    try {
      final res = await http.get(
        Uri.parse('https://api.coinbase.com/v2/exchange-rates?currency=BTC'),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final bif = double.tryParse(
            data['data']?['rates']?['BIF']?.toString() ?? '');
        if (bif != null && bif > 0) {
          rate = bif;
        }
      }
    } catch (_) {
      // 👉 On garde la valeur par défaut
    }

    _cachedRate = rate;
    return rate;
  }

  // ==========================================
  // 💱 FBu → Sats
  // ==========================================
  Future<Map<String, dynamic>> requestOtpFbuToSats({
    required String phone,
    required int amountBif,
  }) async {
    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/exchange/request-otp/',
      body: {'phone': phone, 'amount': amountBif},
    );
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> executeOtpFbuToSats({
    required String phone,
    required int amountBif,
    required String otp,
    required String orderId,
  }) async {
    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/exchange/execute/',
      body: {
        'phone': phone,
        'amount': amountBif,
        'otp': otp,
        'order_id': orderId,
      },
    );
    return Map<String, dynamic>.from(data);
  }

  // ==========================================
  // 💱 Sats → FBu
  // ==========================================
  Future<Map<String, dynamic>> createLightningInvoiceSatsToFbu({
    required int amountSats,
    required String recipientPhone,
  }) async {
    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/exchange/lightning/',
      body: {
        'recipient_phone': recipientPhone,
        'amount_sats': amountSats,
      },
    );
    return Map<String, dynamic>.from(data);
  }

  // ==========================================
  // 📊 STATUT
  // ==========================================
  Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/exchange/orders/$orderId/',
    );
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>?> pollStatus(
    String orderId, {
    void Function(Map<String, dynamic>)? onUpdate,
  }) async {
    for (int i = 0; i < 60; i++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final status = await getOrderStatus(orderId);
        onUpdate?.call(status);
        final s = status['status']?.toString();
        if (s == 'paid' || s == 'failed') return status;
      } catch (_) {}
    }
    return null;
  }
}