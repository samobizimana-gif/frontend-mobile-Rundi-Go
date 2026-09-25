import 'package:flutter/material.dart';
import 'package:rundi_go/features/authentification/services/auth_service.dart';

import '../../../core/api_client.dart';
import '../../../models/chat_message.dart';
import '../../../models/conversation.dart';
import '../../../services/chat_api_service.dart';
import '../../../services/chat_socket_service.dart';

class ConversationScreen extends StatefulWidget {
  final Conversation conversation;

  const ConversationScreen({super.key, required this.conversation});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String? _error;
  List<ChatMessage> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _bindSocket();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    // 👉 On retire nos callbacks pour ne pas recevoir les messages des autres écrans
    ChatSocketService.instance.onMessage = null;
    ChatSocketService.instance.onMessageUpdated = null;
    ChatSocketService.instance.onMessageDeleted = null;
    super.dispose();
  }

  void _bindSocket() {
    final svc = ChatSocketService.instance;
    svc.onMessage = (msg) {
      if (msg.conversationId != widget.conversation.id) return;
      setState(() => _messages.add(msg));
      _scrollToBottom();
    };
    svc.onMessageUpdated = (msg) {
      if (msg.conversationId != widget.conversation.id) return;
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx >= 0) {
        setState(() => _messages[idx] = msg);
      }
    };
    svc.onMessageDeleted = (id) {
      setState(() => _messages.removeWhere((m) => m.id == id));
    };
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list =
          await ChatApiService.instance.getMessages(widget.conversation.id);
      if (!mounted) return;
      setState(() {
        _messages = list;
        _isLoading = false;
      });
      _scrollToBottom();
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
  // 📤 ENVOI VIA WEBSOCKET
  // ==========================================
  Future<void> _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final user = AuthService.instance.currentUser;
    if (user == null) return;

    if (!ChatSocketService.instance.isConnected) {
      _snack("Chat non connecté. Vérifiez votre réseau.");
      return;
    }

    setState(() => _sending = true);

    await ChatSocketService.instance.sendMessage(
      conversationId: widget.conversation.id,
      text: text,
      lang: user.languagePreferee,
    );

    _msgController.clear();
    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
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
    final myId = AuthService.instance.currentUser?.id ?? 0;
    final other = widget.conversation.firstOther(myId);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE3F2FD),
              backgroundImage: other?.displayPhoto != null
                  ? NetworkImage(other!.displayPhoto!)
                  : null,
              child: other?.displayPhoto == null
                  ? const Icon(Icons.person,
                      color: Color(0xFF1E88E5), size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.conversation.displayName(myId),
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessages(myId)),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(int myId) {
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
                onPressed: _loadMessages,
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

    if (_messages.isEmpty) {
      return const Center(
        child: Text("Dites bonjour 👋",
            style: TextStyle(color: Colors.grey, fontSize: 15)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final msg = _messages[i];
        final isMe = msg.sender.id == myId;
        return _MessageBubble(message: msg, isMe: isMe);
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _msgController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Écrire un message...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF1E88E5),
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// BULLE DE MESSAGE
// ==========================================
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final text = message.textToShow;
    final original = message.originalText;
    final isTranslated =
        message.displayText != null && message.displayText != message.originalText;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1E88E5) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 3),
            bottomRight: Radius.circular(isMe ? 3 : 15),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            if (isTranslated && original != null && original.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                "(original : $original)",
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isMe ? Colors.white70 : Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatTime(message.parsedDate),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}