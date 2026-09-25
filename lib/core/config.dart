class AppConfig {
  AppConfig._();


  // 👉L'IP DU BACKEND
  static const String geoBaseUrl = 'http://10.155.246.213:8000/api';
  static const String langBaseUrl = 'http://10.155.246.213:8001/api';

  // ==========================================
  // PAYS PAR DÉFAUT DU VISITEUR
 
  /// bi = Burundi | rw = Rwanda | tz = Tanzanie
  /// ke = Kenya | ug = Ouganda | cd = RD Congo | ot = Autre
  static String defaultCountry = 'bi';

  // ==========================================
  // ⏱️ TIMEOUTS
  // ==========================================
  static const Duration requestTimeout = Duration(seconds: 20);
  static const Duration uploadTimeout = Duration(seconds: 30);

  // ==========================================
  // 🔑 CLÉS DE STOCKAGE
  // ==========================================
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserId = 'user_id';
  static const String keyCountry = 'selected_country';

  // ==========================================
  // 🌐 LANGUES SUPPORTÉES
  // ==========================================
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'fr', 'label': 'Français'},
    {'code': 'en', 'label': 'Anglais'},
    {'code': 'sw', 'label': 'Swahili'},
    {'code': 'rn', 'label': 'Kirundi'},
    {'code': 'ar', 'label': 'Arabe'},
    {'code': 'ha', 'label': 'Haoussa'},
    {'code': 'yo', 'label': 'Yoruba'},
    {'code': 'ig', 'label': 'Igbo'},
    {'code': 'am', 'label': 'Amharique'},
    {'code': 'pt', 'label': 'Portugais'},
  ];

  // ==========================================
  // 🌍 PAYS SUPPORTÉS
  // ==========================================
  static const List<Map<String, String>> supportedCountries = [
    {'code': 'bi', 'label': 'Burundi'},
    {'code': 'rw', 'label': 'Rwanda'},
    {'code': 'tz', 'label': 'Tanzanie'},
    {'code': 'ke', 'label': 'Kenya'},
    {'code': 'ug', 'label': 'Ouganda'},
    {'code': 'cd', 'label': 'RD Congo'},
    {'code': 'ot', 'label': 'Autre'},
  ];

  /// 👉 Le TTS ne marche que pour ces 3 langues
  static const List<String> ttsSupportedLangs = ['fr', 'en', 'sw'];
}