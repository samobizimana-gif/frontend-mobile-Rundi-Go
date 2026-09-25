import 'dart:io';
import 'package:rundi_go/core/api_client.dart';
import 'package:rundi_go/core/config.dart';
import 'package:rundi_go/core/storage_service.dart';

import '../models/user.dart';

class AuthService {
  AuthService._private();
  static final AuthService instance = AuthService._private();

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  bool _bootstrapped = false;

  // ==========================================
  // 🚀 BOOTSTRAP
  // ==========================================
  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    final token = await StorageService.instance.getAccessToken();
    if (token == null) return;

    try {
      await fetchMe();
    } catch (_) {
      await StorageService.instance.clearTokens();
      _currentUser = null;
    }
  }

  // ==========================================
  // 🔐 LOGIN
  // ==========================================
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/auth/login/',
      body: {'username': username, 'password': password},
      auth: false,
    );

    if (data is! Map || data['access'] == null) {
      throw ApiException(message: 'Réponse de login invalide.');
    }

    await StorageService.instance.saveTokens(
      access: data['access'],
      refresh: data['refresh'],
    );

    await fetchMe();
  }

  // ==========================================
  // 📝 REGISTER
  // ==========================================
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String languePreferee,
    required String country,
    bool wantsGerant = false,
    File? photo,
  }) async {
    dynamic result;

    if (photo != null) {
      result = await ApiClient.instance.uploadFile(
        baseUrl: AppConfig.geoBaseUrl,
        path: '/auth/register/',
        file: photo,
        fileField: 'photo',
        fields: {
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'language_preferee': languePreferee,
          'country': country,
          'wants_gerant': wantsGerant ? 'true' : 'false',
        },
        auth: false,
      );
    } else {
      result = await ApiClient.instance.post(
        baseUrl: AppConfig.geoBaseUrl,
        path: '/auth/register/',
        body: {
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'language_preferee': languePreferee,
          'country': country,
          'wants_gerant': wantsGerant,
        },
        auth: false,
      );
    }

    await login(username: username, password: password);
  }

  // ==========================================
  // 👤 GET PROFIL
  // ==========================================
  Future<User> fetchMe() async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/auth/me/',
    );

    if (data is! Map) {
      throw ApiException(message: 'Profil invalide.');
    }

    final user = User.fromJson(Map<String, dynamic>.from(data));
    _currentUser = user;
    await StorageService.instance.saveUserId(user.id);
    return user;
  }

  // ==========================================
  // ✏️ UPDATE
  // ==========================================
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? bio,
    String? country,
    String? languePreferee,
    File? photo,
  }) async {
    dynamic data;

    if (photo != null) {
      data = await ApiClient.instance.uploadFile(
        baseUrl: AppConfig.geoBaseUrl,
        path: '/auth/me/',
        file: photo,
        fileField: 'photo',
        fields: {
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (bio != null) 'bio': bio,
          if (country != null) 'country': country,
          if (languePreferee != null) 'language_preferee': languePreferee,
        },
      );
    } else {
      data = await ApiClient.instance.patch(
        baseUrl: AppConfig.geoBaseUrl,
        path: '/auth/me/',
        body: {
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (bio != null) 'bio': bio,
          if (country != null) 'country': country,
          if (languePreferee != null) 'language_preferee': languePreferee,
        },
      );
    }

    final user = User.fromJson(Map<String, dynamic>.from(data));
    _currentUser = user;
    return user;
  }

  // ==========================================
  // 🌐 LANGUE (endpoint dédié)
  // ==========================================
  Future<User> updateLanguage(String languePreferee) async {
    final data = await ApiClient.instance.patch(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/auth/me/language/',
      body: {'language_preferee': languePreferee},
    );
    final user = User.fromJson(Map<String, dynamic>.from(data));
    _currentUser = user;
    return user;
  }

  // ==========================================
  // 🚪 LOGOUT
  // ==========================================
  Future<void> logout() async {
    _currentUser = null;
    await StorageService.instance.clearTokens();
  }
}