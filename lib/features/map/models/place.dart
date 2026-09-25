import 'package:latlong2/latlong.dart';

class Place {
  final int id;
  final String nom;
  final String categorieNom;
  final String ville;
  final String pays;
  final String? imgUrl;
  final String? description;
  final String? website;
  final String? email;
  final String? phone;
  final String? adresse;
  final bool isActive;
  final bool isVerified;
  final double? prixReference;
  final String commissionStatus;
  final double latitude;
  final double longitude;
  final double distanceM;
  final double distanceKm;
  final List<String> images;

  Place({
    required this.id,
    required this.nom,
    required this.categorieNom,
    required this.ville,
    this.pays = 'bi',
    this.imgUrl,
    this.description,
    this.website,
    this.email,
    this.phone,
    this.adresse,
    this.isActive = true,
    this.isVerified = false,
    this.prixReference,
    this.commissionStatus = 'unpaid',
    required this.latitude,
    required this.longitude,
    this.distanceM = 0,
    this.distanceKm = 0,
    this.images = const [],
  });

  LatLng get position => LatLng(latitude, longitude);

  factory Place.fromGeoJson(Map<String, dynamic> feature) {
    final geom = (feature['geometry'] ?? {}) as Map<String, dynamic>;
    final props = (feature['properties'] ?? {}) as Map<String, dynamic>;
    final coords = (geom['coordinates'] as List?) ?? [0, 0];

    final lng = (coords.isNotEmpty ? coords[0] : 0).toDouble();
    final lat = (coords.length > 1 ? coords[1] : 0).toDouble();

    return Place(
      id: _parseInt(feature['id']),
      nom: props['nom']?.toString() ?? '',
      categorieNom: props['categorie_nom']?.toString() ?? '',
      ville: props['ville']?.toString() ?? '',
      pays: props['pays']?.toString() ?? 'bi',
      imgUrl: props['img_url']?.toString(),
      description: props['description']?.toString(),
      website: props['website']?.toString(),
      email: props['email']?.toString(),
      phone: props['phone']?.toString(),
      adresse: props['adresse']?.toString(),
      isActive: props['is_active'] == true,
      isVerified: props['is_verified'] == true,
      prixReference: _parseDouble(props['prix_reference']),
      commissionStatus: props['commission_status']?.toString() ?? 'unpaid',
      latitude: lat,
      longitude: lng,
      distanceM: _parseDouble(props['distance_m']) ?? 0,
      distanceKm: _parseDouble(props['distance_km']) ?? 0,
      images: _parseImages(props['images']),
    );
  }

  factory Place.fromListJson(Map<String, dynamic> json) {
    double lat = 0, lng = 0;

    final pos = json['position'];
    if (pos is Map && pos['coordinates'] is List) {
      final c = pos['coordinates'] as List;
      if (c.isNotEmpty) lng = (c[0] as num).toDouble();
      if (c.length > 1) lat = (c[1] as num).toDouble();
    } else {
      lat = _parseDouble(json['latitude']) ?? 0;
      lng = _parseDouble(json['longitude']) ?? 0;
    }

    return Place(
      id: _parseInt(json['id']),
      nom: json['nom']?.toString() ?? '',
      categorieNom: json['categorie_nom']?.toString() ?? '',
      ville: json['ville']?.toString() ?? '',
      pays: json['pays']?.toString() ?? 'bi',
      imgUrl: json['img_url']?.toString(),
      latitude: lat,
      longitude: lng,
      distanceM: _parseDouble(json['distance_m']) ?? 0,
      distanceKm: _parseDouble(json['distance_km']) ?? 0,
    );
  }

  factory Place.fromDetailJson(Map<String, dynamic> json) {
    final geom = (json['geometry'] ?? {}) as Map<String, dynamic>;
    final props = (json['properties'] ?? {}) as Map<String, dynamic>;
    final coords = (geom['coordinates'] as List?) ?? [0, 0];

    final lng = (coords.isNotEmpty ? coords[0] : 0).toDouble();
    final lat = (coords.length > 1 ? coords[1] : 0).toDouble();

    return Place(
      id: _parseInt(json['id']),
      nom: props['nom']?.toString() ?? '',
      categorieNom: props['categorie_nom']?.toString() ?? '',
      ville: props['ville']?.toString() ?? '',
      pays: props['pays']?.toString() ?? 'bi',
      imgUrl: props['img_url']?.toString(),
      description: props['description']?.toString(),
      website: props['website']?.toString(),
      email: props['email']?.toString(),
      phone: props['phone']?.toString(),
      adresse: props['adresse']?.toString(),
      isActive: props['is_active'] == true,
      isVerified: props['is_verified'] == true,
      prixReference: _parseDouble(props['prix_reference']),
      commissionStatus: props['commission_status']?.toString() ?? 'unpaid',
      latitude: lat,
      longitude: lng,
      distanceM: _parseDouble(props['distance_m']) ?? 0,
      distanceKm: _parseDouble(props['distance_km']) ?? 0,
      images: _parseImages(props['images']),
    );
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  static List<String> _parseImages(dynamic images) {
    if (images is! List) return const [];
    return images
        .whereType<Map>()
        .map((img) => img['image_url']?.toString())
        .whereType<String>()
        .toList();
  }
}