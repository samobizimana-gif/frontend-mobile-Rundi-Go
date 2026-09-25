import '../core/api_client.dart';
import '../core/config.dart';
import '../models/public_user.dart';

class UserService {
  UserService._private();
  static final UserService instance = UserService._private();

  // 👉 Liste de tous les utilisateurs (avec friend_status)
  Future<List<PublicUser>> getAllUsers() async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/users/',
    );

    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => PublicUser.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  // 👉 Profil public d'un utilisateur
  Future<PublicUser> getUserProfile(int id) async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/users/$id/profile/',
    );
    return PublicUser.fromJson(Map<String, dynamic>.from(data));
  }
}