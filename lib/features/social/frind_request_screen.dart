import 'package:flutter/material.dart';
import 'package:rundi_go/features/authentification/services/auth_service.dart';
import 'package:rundi_go/models/friend_request.dart';
import '../../../core/api_client.dart';
import '../../../services/friend_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  bool _isLoading = true;
  String? _error;
  List<FriendRequest> _requests = [];

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
      final requests = await FriendService.instance.getRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
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

  Future<void> _accept(int id) async {
    try {
      await FriendService.instance.acceptRequest(id);
      if (!mounted) return;
      _snack("Demande acceptée ✅");
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    } on NetworkException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _reject(int id) async {
    try {
      await FriendService.instance.rejectRequest(id);
      if (!mounted) return;
      _snack("Demande refusée");
      _load();
    } on ApiException catch (e) {
      _snack(e.message);
    } on NetworkException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _cancel(int id) async {
    try {
      await FriendService.instance.cancelRequest(id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text("Demandes d'amis",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(child: _buildContent()),
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

    // 👉 On filtre les demandes en attente
    final pending = _requests.where((r) => r.isPending).toList();

    if (pending.isEmpty) {
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
                child: const Icon(Icons.mail_outline,
                    size: 60, color: Color(0xFF1E88E5)),
              ),
              const SizedBox(height: 20),
              const Text("Aucune demande en attente",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final myId = AuthService.instance.currentUser?.id;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pending.length,
      itemBuilder: (context, i) {
        final req = pending[i];
        final incoming = req.toUser.id == myId;
        final other = incoming ? req.fromUser : req.toUser;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFE3F2FD),
                      backgroundImage: other.displayPhoto != null
                          ? NetworkImage(other.displayPhoto!)
                          : null,
                      child: other.displayPhoto == null
                          ? const Icon(Icons.person,
                              color: Color(0xFF1E88E5), size: 24)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(other.fullName,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            incoming
                                ? "Souhaite devenir votre ami"
                                : "En attente de réponse",
                            style: TextStyle(
                              fontSize: 12,
                              color: incoming
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (incoming)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _reject(req.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Refuser"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _accept(req.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Accepter"),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _cancel(req.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Annuler ma demande"),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}