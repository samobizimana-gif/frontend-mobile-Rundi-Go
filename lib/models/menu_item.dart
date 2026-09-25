class MenuItem {
  final int id;
  final String nom;
  final String? description;
  final String? prix;
  final bool isAvailable;

  MenuItem({
    required this.id,
    required this.nom,
    this.description,
    this.prix,
    this.isAvailable = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString(),
      prix: json['prix']?.toString(),
      isAvailable: json['is_available'] != false,
    );
  }
}