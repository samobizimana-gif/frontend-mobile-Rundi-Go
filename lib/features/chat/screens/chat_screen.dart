import 'package:flutter/material.dart';
import 'package:rundi_go/core/error_helper.dart';
import 'package:rundi_go/features/authentification/services/auth_service.dart';

import '../../../core/api_client.dart';
import '../../../models/conversation.dart';
import '../../../services/chat_api_service.dart';
import '../../../services/chat_socket_service.dart';
import 'conversation_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isLoading = true;
  String? _error;
  List<Conversation> _conversations = [];
  bool _wsConnected = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    // ⚠️ On ne disconnecte PAS ici, sinon on perd le WS en changeant d'onglet.
    // Le WS sera déconnecté au logout.
    super.dispose();
  }

  Future<void> _init() async {
    await _connectSocket();
    await _loadConversations();
  }

  Future<void> _connectSocket() async {
    final svc = ChatSocketService.instance;
    svc.onConnected = () {
      if (mounted) setState(() => _wsConnected = true);
    };
    svc.onError = (e) {
      if (mounted) {
        setState(() => _wsConnected = false);
        _snack(e);
      }
    };
    svc.onMessage = (_) => _loadConversations();
    svc.onConversationCreated = (_) => _loadConversations();

    await svc.connect();
    if (mounted) setState(() => _wsConnected = svc.isConnected);
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await ChatApiService.instance.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = list;
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



  void _openConversation(Conversation c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationScreen(conversation: c),
      ),
    ).then((_) => _loadConversations());
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

    if (!AuthService.instance.isLoggedIn) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: const [
                Text("Messagerie",
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: buildEmptyState(
              icon: Icons.lock_outline,
              title: "Connectez-vous pour discuter",
              subtitle:
                  "Allez dans l'onglet Profil pour vous connecter.",
            ),
          ),
        ],
      ),
    );
  }


    final myId = AuthService.instance.currentUser?.id ?? 0;

    return SafeArea(
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                const Text("Messagerie",
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _wsConnected
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _wsConnected
                              ? const Color(0xFF4CAF50)
                              : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _wsConnected ? "En ligne" : "Hors ligne",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _wsConnected
                              ? const Color(0xFF4CAF50)
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // CONTENU
          Expanded(child: _buildContent(myId)),
        ],
      ),
    );
  }

  Widget _buildContent(int myId) {
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
                onPressed: _loadConversations,
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

    if (_conversations.isEmpty) {
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
                child: const Icon(Icons.chat_bubble_outline,
                    size: 60, color: Color(0xFF1E88E5)),
              ),
              const SizedBox(height: 20),
              const Text("Aucune conversation",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                "Ajoutez des amis, puis discutez avec eux.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _conversations.length,
      itemBuilder: (context, i) {
        final c = _conversations[i];
        final other = c.firstOther(myId);

        return GestureDetector(
          onTap: () => _openConversation(c),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
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
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFE3F2FD),
                  backgroundImage: other?.displayPhoto != null
                      ? NetworkImage(other!.displayPhoto!)
                      : null,
                  child: other?.displayPhoto == null
                      ? const Icon(Icons.person,
                          color: Color(0xFF1E88E5), size: 28)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.displayName(myId),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        c.lastMessage ?? "Nouvelle conversation",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }
}