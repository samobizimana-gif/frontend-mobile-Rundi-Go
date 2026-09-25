import 'package:rundi_go/core/api_client.dart';
import 'package:rundi_go/core/config.dart';


class ManagerService {
  ManagerService._private();
  static final ManagerService instance = ManagerService._private();

  // ==========================================
  // 📊 MON STATUT GÉRANT
  // ==========================================
  Future<Map<String, dynamic>> getMe() async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/manager/me/',
    );
    return Map<String, dynamic>.from(data);
  }

  // ==========================================
  // 📋 MES LIEUX
  // ==========================================
  Future<List<Map<String, dynamic>>> getMyPlaces() async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/mine/',
    );
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => Map<String, dynamic>.from(j))
        .toList();
  }

  // ==========================================
  // 📅 RÉSERVATIONS DE MES LIEUX
  // ==========================================
  Future<List<Map<String, dynamic>>> getMyReservations() async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/manager/reservations/',
    );
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => Map<String, dynamic>.from(j))
        .toList();
  }

  // ==========================================
  // 💳 PLANS D'ABONNEMENT
  // ==========================================
  Future<List<Map<String, dynamic>>> getPlans() async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/manager/plans/',
      auth: false,
    );
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => Map<String, dynamic>.from(j))
        .toList();
  }

  // ==========================================
  // 📜 HISTORIQUE ABONNEMENTS
  // ==========================================
  Future<List<Map<String, dynamic>>> getSubscriptions() async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/manager/subscriptions/',
    );
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => Map<String, dynamic>.from(j))
        .toList();
  }

  // ==========================================
  // 💳 PAYER L'ABONNEMENT
  // ==========================================
  Future<Map<String, dynamic>> requestOtp({
    required int planId,
    required String phone,
  }) async {
    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/manager/subscribe/request-otp/',
      body: {'plan_id': planId, 'phone': phone},
    );
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> executeOtp({
    required String orderId,
    required String phone,
    required String otp,
  }) async {
    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/manager/subscribe/execute/',
      body: {'order_id': orderId, 'phone': phone, 'otp': otp},
    );
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> lightning({required int planId}) async {
    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/manager/subscribe/lightning/',
      body: {'plan_id': planId},
    );
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/manager/orders/$orderId/',
    );
    return Map<String, dynamic>.from(data);
  }
}