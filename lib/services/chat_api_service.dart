import '../core/api_client.dart';
import '../core/config.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';

class ChatApiService {
  ChatApiService._private();
  static final ChatApiService instance = ChatApiService._private();

  // ==========================================
  // 📋 CONVERSATIONS
  // ==========================================
  Future<List<Conversation>> getConversations() async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/chat/conversations/',
    );

    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => Conversation.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<Conversation> getConversation(int id) async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/chat/conversations/$id/',
    );
    return Conversation.fromJson(Map<String, dynamic>.from(data));
  }

  // 👉 Créer (ou récupérer) une conversation avec un utilisateur
  Future<Conversation> createConversation({
  required int otherUserId,
  String name = '',
}) async {
  final data = await ApiClient.instance.post(
    baseUrl: AppConfig.geoBaseUrl,
    path: '/chat/conversations/',
    body: {
      'participant_ids': [otherUserId],
      'name': name,
    },
  );
  return Conversation.fromJson(Map<String, dynamic>.from(data));
}


  // ==========================================
  // 💬 MESSAGES
  // ==========================================
  Future<List<ChatMessage>> getMessages(int conversationId) async {
    final data = await ApiClient.instance.get(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/chat/conversations/$conversationId/messages/',
    );

    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((j) => ChatMessage.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  // ⚠️ Note : ton API ne fournit PAS d'endpoint REST pour envoyer un message TEXTE.
  // L'envoi passe par WebSocket (Phase 6.5).
  // Pour les messages VOCAUX, il y a POST /chat/conversations/{id}/voice-messages/

  // ==========================================
  // 🗑️ SUPPRIMER UN MESSAGE
  // ==========================================
  Future<void> deleteMessage({
    required int messageId,
    String scope = 'me', // 'me' | 'all'
  }) async {
    await ApiClient.instance.delete(
      baseUrl: AppConfig.geoBaseUrl,
      path: '/chat/messages/$messageId/',
      query: {'scope': scope},
    );
  }
}