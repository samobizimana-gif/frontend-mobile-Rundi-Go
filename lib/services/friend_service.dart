import 'package:rundi_go/models/friend_request.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../models/public_user.dart';

class FriendService {
  FriendService._private();
  static final FriendService instance = FriendService._private();

  // ==========================================
  // 👥 MES AMIS
  // ==========================================
  Future<List<PublicUser>> getFriends() async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/friends/',
    );

    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => PublicUser.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  // ==========================================
  // 📩 MES DEMANDES D'AMIS (envoyées + reçues)
  // ==========================================
  Future<List<FriendRequest>> getRequests() async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/friend-requests/',
    );

    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => FriendRequest.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  // ==========================================
  // ✉️ ENVOYER UNE DEMANDE
  // ==========================================
  Future<void> sendRequest(int userId) async {
    await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/friend-requests/',
      body: {'user_id': userId},
    );
  }

  // ==========================================
  // ✅ ACCEPTER
  // ==========================================
  Future<void> acceptRequest(int requestId) async {
    await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/friend-requests/$requestId/accept/',
    );
  }

  // ==========================================
  // ❌ REFUSER
  // ==========================================
  Future<void> rejectRequest(int requestId) async {
    await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/friend-requests/$requestId/reject/',
    );
  }

  // ==========================================
  // 🚫 ANNULER (sa propre demande sortante)
  // ==========================================
  Future<void> cancelRequest(int requestId) async {
    await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/friend-requests/$requestId/cancel/',
    );
  }
}