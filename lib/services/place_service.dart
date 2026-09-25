import 'package:rundi_go/features/map/models/place.dart';
import 'package:rundi_go/features/map/models/place_category.dart';

import '../core/api_client.dart';
import '../core/config.dart';

class PlaceService {
  PlaceService._private();
  static final PlaceService instance = PlaceService._private();

  // ==========================================
  // 📋 TOUS LES LIEUX (filtrés par pays)
  // ==========================================
  Future<List<Place>> getAllPlaces({double? lat, double? lng}) async {
    final query = <String, dynamic>{
      'pays': AppConfig.defaultCountry,
    };
    if (lat != null) query['lat'] = lat;
    if (lng != null) query['lng'] = lng;

    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/',
      query: query,
      auth: false,
    );

    if (data is! Map || data['features'] is! List) return [];
    return (data['features'] as List)
        .whereType<Map>()
        .map((f) => Place.fromGeoJson(Map<String, dynamic>.from(f)))
        .toList();
  }

  // ==========================================
  // 📍 SUGGESTIONS
  // ==========================================
  Future<List<Place>> getSuggestions({
    required double lat,
    required double lng,
  }) async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/suggestions/',
      query: {
        'lat': lat,
        'lng': lng,
        'pays': AppConfig.defaultCountry,
      },
      auth: false,
    );

    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => Place.fromListJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  // ==========================================
  // 📍 LIEUX PROCHES
  // ==========================================
  Future<List<Place>> getNearby({
    required double lat,
    required double lng,
    double radiusKm = 5.0,
  }) async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/nearby/',
      query: {
        'lat': lat,
        'lng': lng,
        'radius': radiusKm,
        'pays': AppConfig.defaultCountry,
      },
      auth: false,
    );

    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => Place.fromListJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  // ==========================================
  // 🔍 RECHERCHE
  // ==========================================
  Future<List<Place>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/search/',
      query: {'q': query},
      auth: false,
    );

    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => Place.fromListJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  // ==========================================
  // 💡 AUTOCOMPLETE
  // ==========================================
  Future<List<Map<String, dynamic>>> autocomplete(String query) async {
    if (query.trim().isEmpty) return [];

    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/autocomplete/',
      query: {'q': query},
      auth: false,
    );

    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => Map<String, dynamic>.from(j))
        .toList();
  }

  // ==========================================
  // 🏨 DÉTAIL
  // ==========================================
  Future<Place> getPlaceDetail(int id) async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/$id/',
      auth: false,
    );

    return Place.fromDetailJson(Map<String, dynamic>.from(data));
  }

  // ==========================================
  // 🍽️ MENU
  // ==========================================
  Future<List<Map<String, dynamic>>> getMenu(int placeId) async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/$placeId/menu/',
      auth: false,
    );

    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => Map<String, dynamic>.from(j))
        .toList();
  }

  // ==========================================
  // 🗂️ CATÉGORIES
  // ==========================================
  Future<List<PlaceCategory>> getCategories() async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/categories/',
      auth: false,
    );

    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => PlaceCategory.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }
}