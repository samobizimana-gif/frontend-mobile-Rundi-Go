class PlaceCategory {
  final int id;
  final String nom;
  final String? icon;
  final String? iconUrl;

  PlaceCategory({
    required this.id,
    required this.nom,
    this.icon,
    this.iconUrl,
  });

  // 👉 Icône à afficher (priorité à iconUrl, sinon icône par défaut)
  String? get displayIcon => iconUrl ?? icon;

  factory PlaceCategory.fromJson(Map<String, dynamic> json) {
    return PlaceCategory(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      nom: json['nom']?.toString() ?? '',
      icon: json['icon']?.toString(),
      iconUrl: json['icon_url']?.toString(),
    );
  }
}