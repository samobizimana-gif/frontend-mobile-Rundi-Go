import '../core/api_client.dart';
import '../core/config.dart';
import '../models/menu_item.dart';
import '../models/reservation.dart';

class ReservationService {
  ReservationService._private();
  static final ReservationService instance = ReservationService._private();

  // ==========================================
  // 🍽️ MENU D'UN LIEU
  // ==========================================
  Future<List<MenuItem>> getMenu(int placeId) async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/$placeId/menu/',
      auth: false,
    );

    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => MenuItem.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  // ==========================================
  // 📋 MES RÉSERVATIONS
  // ==========================================
  Future<List<Reservation>> getMyReservations() async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/reservations/',
    );

    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => Reservation.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  // ==========================================
  // ➕ CRÉER UNE RÉSERVATION
  // ==========================================
  Future<Reservation> createReservation({
  required int placeId,
  required String clientNom,
  required String telephone,
  required DateTime date,
  required String heure,
  required int nbPersonnes,
  String? note,
  List<Map<String, int>> itemsData = const [],
}) async {
  // Format date
  final dateStr =
      "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  // Format heure : HH:MM:SS
  final heureStr = heure.length == 5 ? "$heure:00" : heure;

  final body = <String, dynamic>{
    'place': placeId,
    'client_nom': clientNom,
    'telephone': telephone,
    'date': dateStr,
    'heure': heureStr,
    'nb_personnes': nbPersonnes,
  };

  if (note != null && note.isNotEmpty) {
    body['note'] = note;
  }

  if (itemsData.isNotEmpty) {
    body['items_data'] = itemsData
        .map((e) => {
              'item_id': e['item_id'],   // 👈 ATTENTION à l'orthographe
              'quantity': e['quantity'],
            })
        .toList();
  }

  final data = await ApiClient.instance.post(
    baseUrl: AppConfig.geoBaseUrl,
    path: '/places/reservations/',
    body: body,   // 👈 ApiClient fait le jsonEncode() en interne
  );

  return Reservation.fromJson(Map<String, dynamic>.from(data));
}

  // ==========================================
  // ❌ ANNULER
  // ==========================================
  Future<Reservation> cancelReservation(int id) async {
    final data = await ApiClient.instance.patch(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/places/reservations/$id/cancel/',
    );

    return Reservation.fromJson(Map<String, dynamic>.from(data));
  }
}