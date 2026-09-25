import 'package:flutter/material.dart';
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
  int _activeTab = 0;

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _me;

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

  Future<void> _openSubscription() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const ManagerSubscriptionScreen(),
    ),
  );
  if (result == true) {
    // 👉 Recharge le statut
    _load();
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
                ? buildErrorState(message: _error!, onRetry: _load)
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderStatus(),
        const SizedBox(height: 15),
        _buildTabs(),
        const SizedBox(height: 15),
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  // ==========================================
  // HEADER STATUT
  // ==========================================
  Widget _buildHeaderStatus() {
    final status = _me?['manager_status']?.toString() ?? 'none';
    final placesCount = _me?['places_count'] ?? 0;
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
        return _buildMenu();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
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
                  onTap: () =>
                      AppToast.info(context, "Création de lieu (bientôt)"),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add,
                            color: Color(0xFF4CAF50), size: 20),
                        SizedBox(width: 8),
                        Text("+ Nouvel hôtel / restaurant / logement",
                            style: TextStyle(
                                color: Color(0xFF2E7D32),
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
          const Text("Aucun établissement.",
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 5),
          const Text("Créez le premier après paiement.",
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 1 : INVITATIONS
  // ==========================================
  Widget _buildInvitations() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: const [
          Text(
            "Chaque réservation client arrive comme une invitation : acceptez pour confirmer, refusez pour annuler.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 20),
          Text("Aucune invitation reçue.",
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 2 : MENU
  // ==========================================
  Widget _buildMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: const [
          _EmptyDropdown(),
          SizedBox(height: 20),
          Text("Sélectionnez un établissement pour gérer son menu.",
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
              children: const [
                Text("Commissions d'inscription payées : 0 BIF",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text(
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

// ==========================================
// WIDGET : DROPDOWN VIDE
// ==========================================
class _EmptyDropdown extends StatelessWidget {
  const _EmptyDropdown();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: const [
          Expanded(
            child: Text("Choisir un établissement",
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Icon(Icons.keyboard_arrow_down,
              color: Colors.grey, size: 22),
        ],
      ),
    );
  }
}