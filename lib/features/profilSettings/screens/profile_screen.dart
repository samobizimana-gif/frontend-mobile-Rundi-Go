import 'package:flutter/material.dart';
import 'package:rundi_go/features/authentification/screens/login_screen.dart';
import 'package:rundi_go/features/authentification/services/auth_service.dart';
import 'package:rundi_go/features/others/payment/pay_screen.dart';
import 'package:rundi_go/features/profilSettings/screens/edit_profile_screen.dart';
import 'package:rundi_go/features/profilSettings/screens/manager_screen.dart';
import 'package:rundi_go/features/reservation/screens/my_reservation_screen.dart';
import 'package:rundi_go/features/social/friends_screen.dart';
import 'package:rundi_go/features/social/frind_request_screen.dart';
import 'package:rundi_go/features/social/user_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (AuthService.instance.isLoggedIn) {
      try {
        await AuthService.instance.fetchMe();
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    if (result == true) {
      setState(() => _loading = true);
      await _refresh();
    }
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (result == true && mounted) setState(() {});
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.instance.logout();
              if (!mounted) return;
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Déconnexion",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
        ),
      );
    }

    final user = AuthService.instance.currentUser;
    return SafeArea(
      child: user == null ? _buildNotLoggedIn() : _buildLoggedIn(user),
    );
  }

  // ==========================================
  // NON CONNECTÉ
  // ==========================================
  Widget _buildNotLoggedIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  size: 70, color: Color(0xFF1E88E5)),
            ),
            const SizedBox(height: 25),
            const Text("Vous n'êtes pas connecté",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              "Connectez-vous pour accéder à votre profil.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _openLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text("Se connecter",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CONNECTÉ
  // ==========================================
  Widget _buildLoggedIn(user) {
    final photo = user.displayPhoto;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // 1️⃣ BOUTON MODIFIER
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _openEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit,
                          size: 16, color: Color(0xFF1E88E5)),
                      SizedBox(width: 6),
                      Text("Modifier",
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // CARTE PROFIL
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: const Color(0xFFE3F2FD),
                  backgroundImage:
                      photo != null ? NetworkImage(photo) : null,
                  child: photo == null
                      ? const Icon(Icons.person,
                          size: 45, color: Color(0xFF1E88E5))
                      : null,
                ),
                const SizedBox(height: 15),
                Text(user.fullName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("@${user.username}",
                    style: const TextStyle(
                        fontSize: 14, color: Colors.grey)),
                if (user.email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey)),
                ],
                if (user.phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(user.phone,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ],
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(user.bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _badge(Icons.language, user.langue),
                    const SizedBox(width: 8),
                    _badge(Icons.flag_outlined,
                        _countryLabel(user.country)),
                    if (user.isGerant) ...[
                      const SizedBox(width: 8),
                      _badge(Icons.store, "Gérant"),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // 2️⃣ MES RÉSERVATIONS
          _menuItem(
            Icons.calendar_today_outlined,
            "Mes réservations",
            () => _push(const MyReservationsScreen()),
          ),

          // 3️⃣ MES AMIS
          _menuItem(
            Icons.group_outlined,
            "Mes amis",
            () => _push(const FriendsScreen()),
          ),

          // 4️⃣ DEMANDES D'AMIS
          _menuItem(
            Icons.mail_outline,
            "Demandes d'amis",
            () => _push(const FriendRequestsScreen()),
          ),

          // 5️⃣ TOUS LES UTILISATEURS
          _menuItem(
            Icons.people_outline,
            "Tous les utilisateurs",
            () => _push(const UsersScreen()),
          ),

          // 6️⃣ HISTORIQUE PAIEMENTS
          _menuItem(
            Icons.receipt_long,
            "Historique paiements",
            () => _push(const PayScreen()),
          ),

          // 7️⃣ ESPACE GÉRANT (si gérant ou admin)
          if (user.isGerant || user.isAdmin)
            _menuItem(
              Icons.store,
              "Espace Gérant",
              () => _push(const ManagerScreen()),
              highlight: true,
            ),

          // 8️⃣ PARAMÈTRES
          _menuItem(
            Icons.settings_outlined,
            "Paramètres",
            () => _soon("Paramètres"),
          ),

          // 9️⃣ AIDE
          _menuItem(
            Icons.help_outline,
            "Aide",
            () => _soon("Aide"),
          ),

          // 🔟 À PROPOS
          _menuItem(
            Icons.info_outline,
            "À propos",
            () => _soon("À propos"),
          ),
          const SizedBox(height: 15),

          // 🔚 DÉCONNEXION
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text("Se déconnecter",
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================
  void _push(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => _refresh());
  }

  Widget _badge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1E88E5)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF1E88E5),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _countryLabel(String code) {
    const map = {
      'bi': 'Burundi',
      'rw': 'Rwanda',
      'tz': 'Tanzanie',
      'ke': 'Kenya',
      'ug': 'Ouganda',
      'cd': 'RD Congo',
      'ot': 'Autre',
    };
    return map[code] ?? code;
  }

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool highlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: highlight
            ? Border.all(color: const Color(0xFF4CAF50), width: 1.5)
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: highlight
              ? const Color(0xFF4CAF50)
              : const Color(0xFF1E88E5),
        ),
        title: Text(label,
            style: TextStyle(
                fontSize: 15,
                fontWeight:
                    highlight ? FontWeight.bold : FontWeight.w500,
                color: highlight
                    ? const Color(0xFF2E7D32)
                    : Colors.black87)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _soon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature (à venir)")),
    );
  }
}