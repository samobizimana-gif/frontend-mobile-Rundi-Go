class ReservationItem {
  final int id;
  final int itemId;
  final String nom;
  final String? description;
  final String? prix;
  final int quantity;

  ReservationItem({
    required this.id,
    required this.itemId,
    required this.nom,
    this.description,
    this.prix,
    required this.quantity,
  });

  factory ReservationItem.fromJson(Map<String, dynamic> json) {
    return ReservationItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      itemId: json['item'] is int
          ? json['item']
          : int.tryParse('${json['item']}') ?? 0,
      nom: json['nom']?.toString() ?? '',
      description: json['description']?.toString(),
      prix: json['prix']?.toString(),
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse('${json['quantity']}') ?? 0,
    );
  }
}

class Reservation {
  final int id;
  final int placeId;
  final String placeNom;
  final String placeVille;
  final String clientNom;
  final String telephone;
  final String date; // "2026-03-15"
  final String heure; // "19:30:00"
  final int nbPersonnes;
  final String? note;
  final List<ReservationItem> items;
  final String? total;
  final String? totalDisplay;
  final String paymentStatus; // 'pending', 'confirmed', 'cancelled'
  final String? statutDisplay;
  final String createdAt;

  Reservation({
    required this.id,
    required this.placeId,
    required this.placeNom,
    required this.placeVille,
    required this.clientNom,
    required this.telephone,
    required this.date,
    required this.heure,
    required this.nbPersonnes,
    this.note,
    required this.items,
    this.total,
    this.totalDisplay,
    required this.paymentStatus,
    this.statutDisplay,
    required this.createdAt,
  });

  bool get isPending => paymentStatus == 'pending';
  bool get isConfirmed => paymentStatus == 'confirmed';
  bool get isCancelled => paymentStatus == 'cancelled';

  bool get canCancel => isPending;

  factory Reservation.fromJson(Map<String, dynamic> json) {
    List<ReservationItem> items = [];
    final raw = json['items'];
    if (raw is List) {
      items = raw
          .whereType<Map>()
          .map((j) => ReservationItem.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }

    return Reservation(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      placeId: json['place'] is int
          ? json['place']
          : int.tryParse('${json['place']}') ?? 0,
      placeNom: json['place_nom']?.toString() ?? '',
      placeVille: json['place_ville']?.toString() ?? '',
      clientNom: json['client_nom']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      heure: json['heure']?.toString() ?? '',
      nbPersonnes: json['nb_personnes'] is int
          ? json['nb_personnes']
          : int.tryParse('${json['nb_personnes']}') ?? 1,
      note: json['note']?.toString(),
      items: items,
      total: json['total']?.toString(),
      totalDisplay: json['total_display']?.toString(),
      paymentStatus: json['statut']?.toString() ?? 'pending',
      statutDisplay: json['statut_display']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
