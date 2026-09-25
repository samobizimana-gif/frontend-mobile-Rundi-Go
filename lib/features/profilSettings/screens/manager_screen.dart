import 'package:flutter/material.dart';
import 'package:rundi_go/features/profilSettings/gerants/create_place_screen.dart';
import 'package:rundi_go/features/profilSettings/gerants/manager_subscriptiom.screen.dart';
import 'package:rundi_go/features/social/service_manager.dart';

import '../../../core/api_client.dart';
import '../../../core/app_toast.dart';
import '../../../core/error_helper.dart';

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  int _activeTab = 0; // 0=Mes lieux, 1=Invitations, 2=Menu, 3=Abonnement

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _me;

  // 👉 Mes lieux
  bool _loadingPlaces = true;
  List<Map<String, dynamic>> _places = [];

  // 👉 Invitations
  bool _loadingReservations = true;
  List<Map<String, dynamic>> _reservations = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadMe();
    await _loadPlaces();
    await _loadReservations();
  }

  Future<void> _loadMe() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final me = await ManagerService.instance.getMe();
      if (!mounted) return;
      setState(() {
        _me = me;
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

  Future<void> _loadPlaces() async {
    setState(() => _loadingPlaces = true);
    try {
      final list = await ManagerService.instance.getMyPlaces();
      if (!mounted) return;
      setState(() {
        _places = list;
        _loadingPlaces = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _places = [];
        _loadingPlaces = false;
      });
    }
  }

  Future<void> _loadReservations() async {
    setState(() => _loadingReservations = true);
    try {
      final list = await ManagerService.instance.getMyReservations();
      if (!mounted) return;
      setState(() {
        _reservations = list;
        _loadingReservations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reservations = [];
        _loadingReservations = false;
      });
    }
  }

  // ==========================================
  // CRÉER UN ÉTABLISSEMENT
  // ==========================================
  Future<void> _openCreatePlace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePlaceScreen()),
    );
    if (result == true) {
      _loadPlaces();
      _loadMe();
    }
  }

  // ==========================================
  // OUVRIR ABONNEMENT
  // ==========================================
  Future<void> _openSubscription() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManagerSubscriptionScreen()),
    );
    if (result == true) {
      _loadMe();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text("Espace Gérant",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Quitter",
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
              )
            : _error != null
                ? buildErrorState(message: _error!, onRetry: _loadAll)
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    color: const Color(0xFF4CAF50),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderStatus(),
                          const SizedBox(height: 15),
                          _buildTabs(),
                          const SizedBox(height: 15),
                          _buildTabContent(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================
  Widget _buildHeaderStatus() {
    final status = _me?['manager_status']?.toString() ?? 'none';
    final placesCount = _me?['places_count'] ?? _places.length;
    final hasSub = _me?['has_active_subscription'] == true;
    final commissions = _me?['commissions_due_bif'] ?? 0;

    String statusLabel;
    Color statusColor;
    switch (status) {
      case 'active':
        statusLabel = "actif";
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'pending_payment':
        statusLabel = "pending_payment";
        statusColor = const Color(0xFFFB8C00);
        break;
      case 'expired':
        statusLabel = "expiré";
        statusColor = Colors.red;
        break;
      default:
        statusLabel = "aucun abonnement";
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Statut : ",
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text(statusLabel,
                  style: TextStyle(
                      fontSize: 13,
                      color: statusColor,
                      fontWeight: FontWeight.bold)),
              const Text(" · ",
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text("$placesCount établissement(s)",
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          if (!hasSub) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFB8C00)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Abonnement inactif ou expiré. Vous ne pouvez pas publier de lieu.",
                      style: TextStyle(
                          fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _activeTab = 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFB8C00),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text("Payer / Renouveler",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (commissions is int && commissions > 0) ...[
            const SizedBox(height: 8),
            Text("Commissions dues : $commissions BIF",
                style: const TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // ONGLETS
  // ==========================================
  Widget _buildTabs() {
    final tabs = ['Mes lieux', 'Invitations', 'Menu', 'Abonnement'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _activeTab == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = i),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF4CAF50)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(tabs[i],
                      style: TextStyle(
                        color:
                            active ? Colors.white : Colors.black87,
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 12,
                      )),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildMyPlaces();
      case 1:
        return _buildInvitations();
      case 2:
        return _buildMenuTab();
      case 3:
        return _buildSubscription();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // ONGLET 0 : MES LIEUX
  // ==========================================
  Widget _buildMyPlaces() {
    final hasSub = _me?['has_active_subscription'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info + bouton créer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Créer un établissement",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: hasSub
                      ? _openCreatePlace
                      : () => AppToast.warning(context,
                          "Activez votre abonnement pour publier un lieu"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: hasSub
                          ? const Color(0xFF4CAF50).withOpacity(0.15)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add,
                            color: hasSub
                                ? const Color(0xFF4CAF50)
                                : Colors.grey,
                            size: 20),
                        const SizedBox(width: 8),
                        Text("+ Nouvel hôtel / restaurant / logement",
                            style: TextStyle(
                                color: hasSub
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Un lieu créé est masqué jusqu'à vérification admin.",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Liste des lieux
          if (_loadingPlaces)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              ),
            )
          else if (_places.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                children: [
                  Icon(Icons.store_outlined,
                      size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("Aucun établissement",
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey)),
                  SizedBox(height: 5),
                  Text("Créez le premier après paiement.",
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          else
            ..._places.map((p) => _placeTile(p)),
        ],
      ),
    );
  }

  Widget _placeTile(Map<String, dynamic> place) {
    // 👉 Supporte 2 formats : GeoJSON ou objet simple
    final props = place['properties'] is Map
        ? Map<String, dynamic>.from(place['properties'])
        : place;

    final nom = props['nom']?.toString() ?? 'Sans nom';
    final ville = props['ville']?.toString() ?? '';
    final imgUrl = props['img_url']?.toString();
    final isActive = props['is_active'] == true;
    final isVerified = props['is_verified'] == true;

    String statusLabel;
    Color statusColor;
    if (isVerified) {
      statusLabel = "Publié";
      statusColor = const Color(0xFF4CAF50);
    } else if (isActive) {
      statusLabel = "En attente de vérification";
      statusColor = const Color(0xFFFB8C00);
    } else {
      statusLabel = "Masqué";
      statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (imgUrl != null && imgUrl.isNotEmpty)
                ? Image.network(
                    imgUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey.shade200,
                      child:
                          const Icon(Icons.image, color: Colors.grey),
                    ),
                  )
                : Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(ville,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 1 : INVITATIONS (réservations)
  // ==========================================
  Widget _buildInvitations() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            "Chaque réservation client arrive comme une invitation : acceptez pour confirmer, refusez pour annuler.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (_loadingReservations)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              ),
            )
          else if (_reservations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Text("Aucune invitation reçue.",
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            )
          else
            ..._reservations.map((r) => _reservationTile(r)),
        ],
      ),
    );
  }

  Widget _reservationTile(Map<String, dynamic> r) {
    final clientNom = r['client_nom']?.toString() ?? '';
    final date = r['date']?.toString() ?? '';
    final heure = r['heure']?.toString() ?? '';
    final nb = r['nb_personnes'] ?? 1;
    final placeNom = r['place_nom']?.toString() ?? '';
    final statut = r['statut']?.toString() ?? 'pending';
    final total = r['total_display']?.toString() ?? r['total']?.toString() ?? '';

    Color statutColor;
    String statutLabel;
    switch (statut) {
      case 'confirmed':
        statutColor = const Color(0xFF4CAF50);
        statutLabel = "Confirmée";
        break;
      case 'cancelled':
        statutColor = Colors.red;
        statutLabel = "Annulée";
        break;
      default:
        statutColor = const Color(0xFFFB8C00);
        statutLabel = "En attente";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
          Row(
            children: [
              Expanded(
                child: Text(placeNom,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(statutLabel,
                    style: TextStyle(
                        fontSize: 10,
                        color: statutColor,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _row(Icons.person, clientNom),
          const SizedBox(height: 4),
          _row(Icons.calendar_today, "$date • $heure"),
          const SizedBox(height: 4),
          _row(Icons.people_outline, "$nb personne(s)"),
          if (total.isNotEmpty) ...[
            const SizedBox(height: 4),
            _row(Icons.attach_money, total),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ),
      ],
    );
  }

  // ==========================================
  // ONGLET 2 : MENU
  // ==========================================
  Widget _buildMenuTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _places.isEmpty
                        ? "Aucun établissement"
                        : _places.first['properties']?['nom']?.toString() ??
                            _places.first['nom']?.toString() ??
                            "Choisir un établissement",
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down,
                    color: Colors.grey, size: 22),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("Sélectionnez un établissement pour gérer son menu.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 3 : ABONNEMENT
  // ==========================================
  Widget _buildSubscription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Commissions d'inscription payées : 0 BIF",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  "10 % du prix de référence de chaque logement, payée d'avance à la plateforme avant publication.",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _openSubscription,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: const Center(
                child: Text("Renouveler (Lumicash / Lightning)",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "L'abonnement gérant est mensuel et multi-établissements. Payez par Lumicash ou Lightning.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}