import 'package:flutter/material.dart';

import '../../../core/api_client.dart';
import '../../../models/public_user.dart';
import '../../../services/friend_service.dart';
import '../../../services/user_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  List<PublicUser> _users = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await UserService.instance.getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
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

  List<PublicUser> get _filtered {
    if (_search.isEmpty) return _users;
    final q = _search.toLowerCase();
    return _users.where((u) {
      return u.fullName.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q);
    }).toList();
  }

  // ==========================================
  // ACTIONS
  // ==========================================
  Future<void> _sendRequest(PublicUser user) async {
    try {
      await FriendService.instance.sendRequest(user.id);
      if (!mounted) return;
      _snack("Demande envoyée à ${user.fullName}");
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    } on NetworkException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _cancelRequest(PublicUser user, int requestId) async {
    try {
      await FriendService.instance.cancelRequest(requestId);
      if (!mounted) return;
      _snack("Demande annulée");
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    } on NetworkException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
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
        title: const Text("Utilisateurs",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Recherche
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _search = v.trim()),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: "Rechercher un utilisateur...",
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 15),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Réessayer"),
              ),
            ],
          ),
        ),
      );
    }

    final users = _filtered;

    if (users.isEmpty) {
      return const Center(
        child: Text("Aucun utilisateur trouvé",
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final user = users[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _UserTile(
            user: user,
            onSend: () => _sendRequest(user),
            onCancel: (id) => _cancelRequest(user, id),
          ),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final PublicUser user;
  final VoidCallback onSend;
  final ValueChanged<int> onCancel;

  const _UserTile({
    required this.user,
    required this.onSend,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFE3F2FD),
            backgroundImage: user.displayPhoto != null
                ? NetworkImage(user.displayPhoto!)
                : null,
            child: user.displayPhoto == null
                ? const Icon(Icons.person,
                    color: Color(0xFF1E88E5), size: 28)
                : null,
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text("@${user.username}",
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),

          // Action
          _buildAction(context),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context) {
    if (user.isFriend) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.check, size: 14, color: Color(0xFF4CAF50)),
            SizedBox(width: 4),
            Text("Ami",
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (user.hasOutgoing) {
      return TextButton(
        onPressed: () => onCancel(0), // 👉 à affiner avec l'id de la request
        child: const Text("En attente",
            style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }

    if (user.hasIncoming) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFB8C00).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text("À accepter",
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFFFB8C00),
                fontWeight: FontWeight.bold)),
      );
    }

    // none → bouton "Ajouter"
    return ElevatedButton(
      onPressed: onSend,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text("Ajouter",
          style:
              TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}