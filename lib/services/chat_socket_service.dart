import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../core/config.dart';
import '../core/storage_service.dart';
import '../models/chat_message.dart';

/// Callbacks fournis par l'UI.
typedef OnMessage = void Function(ChatMessage msg);
typedef OnConversationCreated = void Function(int conversationId);
typedef OnMessageUpdated = void Function(ChatMessage msg);
typedef OnMessageDeleted = void Function(int messageId);
typedef OnError = void Function(String error);
typedef OnConnected = void Function();

class ChatSocketService {
  ChatSocketService._private();
  static final ChatSocketService instance = ChatSocketService._private();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  bool _isConnecting = false;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // 👉 Callbacks à brancher par l'UI
  OnMessage? onMessage;
  OnMessageUpdated? onMessageUpdated;
  OnMessageDeleted? onMessageDeleted;
  OnConversationCreated? onConversationCreated;
  OnError? onError;
  OnConnected? onConnected;

  // ==========================================
  // 🔌 CONNEXION
  // ==========================================
  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;

    try {
      final token = await StorageService.instance.getAccessToken();
      if (token == null) {
        _isConnecting = false;
        onError?.call("Non connecté");
        return;
      }

      // 👉 URL WebSocket : ws://<host>:8000/ws/chat/?token=<jwt>
      // On remplace http:// par ws://
      final base = AppConfig.geoBaseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://')
          .replaceFirst('/api', ''); // ⚠️ Le WS n'est PAS sous /api

      final url = '$base/ws/chat/?token=$token';

      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;

      _isConnected = true;
      _isConnecting = false;
      onConnected?.call();

      _sub = _channel!.stream.listen(
        _handleIncoming,
        onError: (e) {
          _isConnected = false;
          onError?.call("Erreur socket : $e");
          _scheduleReconnect();
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      onError?.call("Impossible de se connecter au chat.");
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isConnected) connect();
    });
  }

  // ==========================================
  // 📥 RÉCEPTION
  // ==========================================
  void _handleIncoming(dynamic raw) {
    try {
      final data = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final type = data['type']?.toString();

      switch (type) {
        case 'chat.message':
          final msg = ChatMessage.fromJson(
              Map<String, dynamic>.from(data['message'] ?? data));
          onMessage?.call(msg);
          break;

        case 'translation.ready':
        case 'chat.message_updated':
          final msg = ChatMessage.fromJson(
              Map<String, dynamic>.from(data['message'] ?? data));
          onMessageUpdated?.call(msg);
          break;

        case 'chat.message_deleted':
          final id = data['message_id'];
          if (id is int) onMessageDeleted?.call(id);
          break;

        case 'conversation.created':
          final cid = data['conversation_id'];
          if (cid is int) onConversationCreated?.call(cid);
          break;
      }
    } catch (e) {
      // ignore silencieux
    }
  }

  // ==========================================
  // 📤 ENVOI
  // ==========================================
  Future<void> sendMessage({
    required int conversationId,
    required String text,
    required String lang,
  }) async {
    if (!_isConnected || _channel == null) {
      onError?.call("Chat non connecté. Réessayez.");
      return;
    }

    final payload = {
      'type': 'chat.message',
      'conversation_id': conversationId,
      'text': text,
      'lang': lang,
    };
    _channel!.sink.add(jsonEncode(payload));
  }

  // ==========================================
  // 🆕 CRÉER UNE CONVERSATION VIA WS
  // ==========================================
  Future<void> createConversation({
    required List<int> participantIds,
    String name = '',
  }) async {
    if (!_isConnected || _channel == null) {
      onError?.call("Chat non connecté. Réessayez.");
      return;
    }

    final payload = {
      'type': 'conversation.create',
      'participant_ids': participantIds,
      'name': name,
    };
    _channel!.sink.add(jsonEncode(payload));
  }

  // ==========================================
  // 🔌 DÉCONNEXION
  // ==========================================
  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close(ws_status.normalClosure);
    _channel = null;
    _isConnected = false;
  }
}