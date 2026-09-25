import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class StorageService {
  StorageService._private();
  static final StorageService instance = StorageService._private();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==========================================
  // 🔑 TOKENS
  // ==========================================
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    final p = await _p;
    await p.setString(AppConfig.keyAccessToken, access);
    await p.setString(AppConfig.keyRefreshToken, refresh);
  }

  Future<String?> getAccessToken() async {
    final p = await _p;
    return p.getString(AppConfig.keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    final p = await _p;
    return p.getString(AppConfig.keyRefreshToken);
  }

  Future<void> clearTokens() async {
    final p = await _p;
    await p.remove(AppConfig.keyAccessToken);
    await p.remove(AppConfig.keyRefreshToken);
    await p.remove(AppConfig.keyUserId);
  }

  // ==========================================
  // 👤 USER ID
  // ==========================================
  Future<void> saveUserId(int id) async {
    final p = await _p;
    await p.setInt(AppConfig.keyUserId, id);
  }

  Future<int?> getUserId() async {
    final p = await _p;
    return p.getInt(AppConfig.keyUserId);
  }

  // ==========================================
  // 🧹 RESET COMPLET
  // ==========================================
  Future<void> clearAll() async {
    final p = await _p;
    await p.clear();
  }
}