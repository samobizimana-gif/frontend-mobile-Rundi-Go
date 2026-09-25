import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:rundi_go/core/api_client.dart';
import 'package:rundi_go/core/config.dart';
import 'package:rundi_go/core/storage_service.dart';


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


  // ==========================================
// 🏨 CRÉER UN ÉTABLISSEMENT
// ==========================================
Future<Map<String, dynamic>> createPlace({
  required String nom,
  required int categorieId,
  required String ville,
  required double latitude,
  required double longitude,
  String pays = 'bi',
  String? adresse,
  String? description,
  String? website,
  String? email,
  String? phone,
  double? prixReference,
  File? image,
  required dynamic http,
}) async {
  // 👉 Position GeoJSON : [lng, lat]
  final position = '{"type":"Point","coordinates":[$longitude,$latitude]}';

  final fields = <String, String>{
    'nom': nom,
    'categorie': categorieId.toString(),
    'ville': ville,
    'pays': pays,
    'position': position,
  };

  if (adresse != null && adresse.isNotEmpty) fields['adresse'] = adresse;
  if (description != null && description.isNotEmpty) {
    fields['description'] = description;
  }
  if (website != null && website.isNotEmpty) fields['website'] = website;
  if (email != null && email.isNotEmpty) fields['email'] = email;
  if (phone != null && phone.isNotEmpty) fields['phone'] = phone;
  if (prixReference != null && prixReference > 0) {
    fields['prix_reference'] = prixReference.toString();
  }

  // 👉 Multipart obligatoire (même sans image)
  final url = Uri.parse('${AppConfig.geoBaseUrl}/places/');
  final request = http.MultipartRequest('POST', url);

  // 👉 Token
  final token = await StorageService.instance.getAccessToken();
  if (token != null) {
    request.headers['Authorization'] = 'Bearer $token';
  }
  request.headers['Accept'] = 'application/json';

  // 👉 Champs
  request.fields.addAll(fields);

  // 👉 Image (si présente)
  if (image != null) {
    final ext = image.path.split('.').last.toLowerCase();
    MediaType? contentType;
    if (ext == 'png') {
      contentType = MediaType('image', 'png');
    } else if (ext == 'webp') {
      contentType = MediaType('image', 'webp');
    } else {
      contentType = MediaType('image', 'jpeg');
    }
    request.files.add(
      await http.MultipartFile.fromPath(
        'img',
        image.path,
        contentType: contentType,
      ),
    );
  }

  // 👉 Envoi + gestion d'erreur propre
  try {
    final streamed = await request.send().timeout(AppConfig.uploadTimeout);
    final response = await http.Response.fromStream(streamed);

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(body ?? {});
    }

    // 👉 Extraction du message d'erreur
    String message = "Erreur ${response.statusCode}";
    if (body is Map) {
      if (body['detail'] != null) {
        message = body['detail'].toString();
      } else {
        final firstKey = body.keys.first;
        final firstVal = body[firstKey];
        if (firstVal is List && firstVal.isNotEmpty) {
          message = "$firstKey : ${firstVal.first}";
        } else {
          message = "$firstKey : $firstVal";
        }
      }
    } else if (response.body.isNotEmpty) {
      message = response.body;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      body: body,
    );
  } on TimeoutException {
    throw NetworkException("Délai d'envoi dépassé. Réessayez.");
  } on SocketException {
    throw NetworkException("Impossible de contacter le serveur.");
  }
}
}