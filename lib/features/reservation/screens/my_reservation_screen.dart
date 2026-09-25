import 'package:flutter/material.dart';
import 'package:rundi_go/features/others/payment/payment_sheet.dart';

import '../../../core/api_client.dart';
import '../../../core/app_toast.dart';
import '../../../core/error_helper.dart';
import '../../../models/reservation.dart';
import '../../../services/reservation_service.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Reservation> _reservations = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ReservationService.instance.getMyReservations();
      if (!mounted) return;
      setState(() {
        _reservations = list;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Erreur : $e";
        _isLoading = false;
      });
    }
  }

  // ==========================================
  // ❌ ANNULER
  // ==========================================
  Future<void> _cancel(Reservation r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Annuler la réservation ?"),
        content: Text(
            "Réservation chez ${r.placeNom} le ${r.date} à ${r.heure}."),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Non"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Oui, annuler",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ReservationService.instance.cancelReservation(r.id);
      if (!mounted) return;
      AppToast.success(context, "Réservation annulée");
      _load();
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } on NetworkException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    }
  }

  // ==========================================
  // 💳 PAYER
  // ==========================================
  Future<void> _pay(Reservation r) async {
  // 👉 Parse robuste : accepte "10000", "10000.00", "10 000", "10000,00"
  final total = _parseTotal(r.total) > 0
      ? _parseTotal(r.total)
      : _parseTotal(r.totalDisplay);

  if (total <= 0) {
    AppToast.error(context, "Montant invalide pour cette réservation");
    return;
  }

  final ok = await PaymentSheet.show(
    context,
    target: PaymentTarget.reservation,
    referenceId: r.id,
    amountBif: total,
  );

  if (ok == true && mounted) {
    AppToast.success(context, "Paiement réussi ✅");
    _load();
  }
}

/// 👉 Convertit une chaîne en entier, gère les décimales, les espaces, etc.
int _parseTotal(String? s) {
  if (s == null || s.trim().isEmpty) return 0;
  // Enlève espaces, remplace virgule par point
  final cleaned = s.replaceAll(' ', '').replaceAll(',', '.');
  // Essaie int direct (ex: "10000")
  final asInt = int.tryParse(cleaned);
  if (asInt != null) return asInt;
  // Sinon, essaie double puis arrondit (ex: "10000.00" → 10000)
  final asDouble = double.tryParse(cleaned);
  if (asDouble != null) return asDouble.round();
  return 0;
}


  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text("Mes réservations",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
              )
            : _error != null
                ? buildErrorState(message: _error!, onRetry: _load)
                : _reservations.isEmpty
                    ? buildEmptyState(
                        icon: Icons.calendar_today_outlined,
                        title: "Aucune réservation",
                        subtitle:
                            "Vos réservations apparaîtront ici une fois créées.",
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF1E88E5),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _reservations.length,
                          itemBuilder: (context, i) {
                            final r = _reservations[i];
                            return _ReservationTile(
                              reservation: r,
                              onCancel: () => _cancel(r),
                              onPay: () => _pay(r),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

// ==========================================
// TUILE RÉSERVATION
// ==========================================

class _ReservationTile extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onCancel;
  final VoidCallback onPay;

  const _ReservationTile({
    required this.reservation,
    required this.onCancel,
    required this.onPay,
  });

  Color _statusColor() {
    if (reservation.isConfirmed) return const Color(0xFF4CAF50);
    if (reservation.isCancelled) return Colors.red;
    return const Color(0xFFFB8C00);
  }

  String _statusLabel() {
    if (reservation.isConfirmed) return "Confirmée";
    if (reservation.isCancelled) return "Annulée";
    return "En attente";
  }

  IconData _statusIcon() {
    if (reservation.isConfirmed) return Icons.check_circle;
    if (reservation.isCancelled) return Icons.cancel;
    return Icons.schedule;
  }

  /// 👉 Bouton Payer visible SEULEMENT si confirmée et non payée
  bool get _canPay {
    if (reservation.isCancelled) return false;
    if (!reservation.isConfirmed) return false;
    if (reservation.paymentStatus.toLowerCase() == 'paid') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TITRE + STATUT
          Row(
            children: [
              Expanded(
                child: Text(reservation.placeNom,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor().withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(_statusIcon(), size: 12, color: _statusColor()),
                    const SizedBox(width: 4),
                    Text(_statusLabel(),
                        style: TextStyle(
                            fontSize: 11,
                            color: _statusColor(),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(reservation.placeVille,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Divider(height: 20),

          // INFOS
          _row(Icons.calendar_today, "${reservation.date}"),
          const SizedBox(height: 6),
          _row(Icons.access_time, reservation.heure),
          const SizedBox(height: 6),
          _row(
              Icons.people_outline,
              "${reservation.nbPersonnes} personne${reservation.nbPersonnes > 1 ? 's' : ''}"),

          // PLATS
          if (reservation.items.isNotEmpty) ...[
            const Divider(height: 20),
            const Text("Plats :",
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...reservation.items.map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text("${it.quantity}x ",
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E88E5))),
                      Expanded(
                        child: Text(it.nom,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                )),
          ],

          // TOTAL
          if (reservation.totalDisplay != null ||
              reservation.total != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                const Text("Total :",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  reservation.totalDisplay ?? reservation.total ?? '',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5)),
                ),
              ],
            ),
          ],

          // 👉 INFO : en attente de confirmation
          if (!reservation.isConfirmed && !reservation.isCancelled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFB8C00)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFFB8C00)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "En attente de confirmation du gérant. Vous pourrez payer dès qu'elle sera confirmée.",
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 👉 BOUTON PAYER (uniquement si confirmée et non payée)
          if (_canPay && reservation.total != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.payment, size: 18),
                label: const Text("Payer maintenant",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],

          // BOUTON ANNULER
          if (reservation.canCancel) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Annuler la réservation"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

