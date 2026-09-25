import 'package:flutter/material.dart';
import 'package:rundi_go/features/chat/screens/conversation_screen.dart';

import '../../../core/api_client.dart';
import '../../../core/app_toast.dart';
import '../../../core/error_helper.dart';
import '../../../models/public_user.dart';
import '../../../services/chat_api_service.dart';
import '../../../services/friend_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  bool _isLoading = true;
  String? _error;
  List<PublicUser> _friends = [];
  int? _openingId;

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
      final friends = await FriendService.instance.getFriends();
      if (!mounted) return;
      setState(() {
        _friends = friends;
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

  // 👉 Ouvre la conversation avec cet ami
  Future<void> _openChat(PublicUser friend) async {
    setState(() => _openingId = friend.id);
    try {
      // 1. Crée ou récupère la conversation
      final conv = await ChatApiService.instance.createConversation(
        otherUserId: friend.id,
      );

      if (!mounted) return;
      setState(() => _openingId = null);

      // 2. Navigue vers la conversation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationScreen(conversation: conv),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _openingId = null);
        AppToast.error(context, e.message);
      }
    } on NetworkException catch (e) {
      if (mounted) {
        setState(() => _openingId = null);
        AppToast.error(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _openingId = null);
        AppToast.error(context, "Erreur : $e");
      }
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
        title: const Text("Mes amis",
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
                : _friends.isEmpty
                    ? buildEmptyState(
                        icon: Icons.people_outline,
                        title: "Aucun ami pour l'instant",
                        subtitle:
                            "Allez dans 'Utilisateurs' pour en ajouter.",
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF1E88E5),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _friends.length,
                          itemBuilder: (context, i) {
                            final user = _friends[i];
                            final opening = _openingId == user.id;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: opening
                                    ? null
                                    : () => _openChat(user),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.05),
                                          blurRadius: 8),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor:
                                            const Color(0xFFE3F2FD),
                                        backgroundImage:
                                            user.displayPhoto != null
                                                ? NetworkImage(
                                                    user.displayPhoto!)
                                                : null,
                                        child: user.displayPhoto == null
                                            ? const Icon(Icons.person,
                                                color: Color(0xFF1E88E5),
                                                size: 28)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(user.fullName,
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 2),
                                            Text("@${user.username}",
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      if (opening)
                                        const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child:
                                              CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Color(0xFF1E88E5)),
                                        )
                                      else
                                        const Icon(
                                            Icons.chat_bubble_outline,
                                            color: Color(0xFF1E88E5),
                                            size: 24),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}