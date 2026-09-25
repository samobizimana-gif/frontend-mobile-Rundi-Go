import 'dart:async';

import '../core/api_client.dart';
import '../core/config.dart';
import '../models/payment.dart';
import '../models/exchange_order.dart';

class PaymentService {
  PaymentService._private();
  static final PaymentService instance = PaymentService._private();

  // ==========================================
  // 💳 PAIEMENT RÉSERVATION
  // ==========================================

  /// Demande OTP pour payer une réservation (Lumicash).
  Future<OtpRequestResponse> requestReservationOtp({
    required int reservationId,
    required String phone,
  }) async {
    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/reservations/$reservationId/pay/request-otp/',
      body: {'phone': phone},
    );
    return OtpRequestResponse.fromJson(Map<String, dynamic>.from(data));
  }

  /// Exécute le paiement avec OTP.
  Future<bool> executeReservationPayment({
    required int reservationId,
    required String phone,
    required String otp,
  }) async {
    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/reservations/$reservationId/pay/execute/',
      body: {'phone': phone, 'otp': otp},
    );
    return data is Map && data['success'] == true;
  }

  /// Génère une facture Lightning pour la réservation.
  Future<LightningResponse> reservationLightning(int reservationId) async {
    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/reservations/$reservationId/pay/lightning/',
    );
    return LightningResponse.fromJson(Map<String, dynamic>.from(data));
  }

  /// Polling du statut de paiement (polling 5s côté UI).
  Future<OrderStatusResponse> reservationPaymentStatus(int reservationId) async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/reservations/$reservationId/pay/status/',
    );
    return OrderStatusResponse.fromJson(Map<String, dynamic>.from(data));
  }

  // ==========================================
  // 💱 ÉCHANGE LIBRE
  // ==========================================

  Future<ExchangeOrder> exchangeRequestOtp({
    required String phone,
    required int amountBif,
  }) async {
    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/exchange/request-otp/',
      body: {'phone': phone, 'amount': amountBif},
    );
    return ExchangeOrder.fromJson(Map<String, dynamic>.from(data));
  }

  Future<bool> exchangeExecute({
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
    return data is Map && data['success'] == true;
  }

  Future<LightningResponse> exchangeLightning({
    required String recipientPhone,
    required int amountBif,
  }) async {
    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/exchange/lightning/',
      body: {'recipient_phone': recipientPhone, 'amount_bif': amountBif},
    );
    return LightningResponse.fromJson(Map<String, dynamic>.from(data));
  }

  Future<OrderStatusResponse> exchangeOrderStatus(String orderId) async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/exchange/orders/$orderId/',
    );
    return OrderStatusResponse.fromJson(Map<String, dynamic>.from(data));
  }

  // ==========================================
  // 📜 HISTORIQUE
  // ==========================================
  Future<HistoryResponse> getHistory() async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/history/',
    );
    return HistoryResponse.fromJson(Map<String, dynamic>.from(data));
  }

  // ==========================================
  // 🔁 POLLING GÉNÉRIQUE
  // ==========================================
  /// Poll un statut toutes les 5 secondes, jusqu'à un max d'essais.
  /// Retourne la dernière réponse ou null si timeout.
  Future<OrderStatusResponse?> pollStatus({
    required Future<OrderStatusResponse> Function() fetcher,
    int maxAttempts = 60, // 60 × 5s = 5 min
    void Function(OrderStatusResponse)? onUpdate,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final status = await fetcher();
        onUpdate?.call(status);
        if (status.isPaid || status.isFailed) return status;
      } catch (_) {
        // on continue
      }
    }
    return null;
  }
}