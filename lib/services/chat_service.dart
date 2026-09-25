import 'package:rundi_go/features/chat/models/chat_user.dart';
import 'package:rundi_go/features/chat/models/message.dart';


class ChatService {
  ChatService._private();
  static final ChatService instance = ChatService._private();

  // 👉 Contacts mockés (à remplacer par l'API)
  final List<ChatUser> _contacts = [
    ChatUser(
      id: 'u2',
      username: 'alice',
      fullName: 'Alice N.',
      photoUrl: 'https://i.pravatar.cc/150?img=20',
      isOnline: true,
    ),
    ChatUser(
      id: 'u3',
      username: 'kevin',
      fullName: 'Kevin M.',
      photoUrl: 'https://i.pravatar.cc/150?img=15',
      isOnline: true,
    ),
    ChatUser(
      id: 'u4',
      username: 'sandrine',
      fullName: 'Sandrine B.',
      photoUrl: 'https://i.pravatar.cc/150?img=25',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ChatUser(
      id: 'u5',
      username: 'jean',
      fullName: 'Jean-Paul K.',
      photoUrl: 'https://i.pravatar.cc/150?img=33',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // 👉 Messages stockés par conversation (userId → messages)
  final Map<String, List<Message>> _messages = {};

  // ==========================================
  // CONTACTS
  // ==========================================
  List<ChatUser> get contacts => List.unmodifiable(_contacts);

  List<ChatUser> get onlineContacts =>
      _contacts.where((c) => c.isOnline).toList();

  ChatUser? getContactById(String id) {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // MESSAGES
  // ==========================================
  List<Message> getMessages(String otherUserId) {
    return _messages[otherUserId] ?? [];
  }

  // 👉 Envoie un message (aujourd'hui local, demain API)
  Message sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) {
    final msg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
    );

    _messages.putIfAbsent(receiverId, () => []);
    _messages[receiverId]!.add(msg);
    return msg;
  }

  // 👉 Initialise une conversation avec des messages de démo
  void seedDemoMessages(String otherUserId) {
    if (_messages.containsKey(otherUserId)) return;

    _messages[otherUserId] = [
      Message(
        id: '1',
        senderId: otherUserId,
        receiverId: 'me',
        content: 'Salut ! Comment ça va ?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Message(
        id: '2',
        senderId: 'me',
        receiverId: otherUserId,
        content: 'Ça va bien, merci ! Et toi ?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 28)),
      ),
      Message(
        id: '3',
        senderId: otherUserId,
        receiverId: 'me',
        content: 'Super ! Tu es où là ?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }
}