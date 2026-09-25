import '../models/chat_user.dart';
import '../models/message.dart';

// 👉 États possibles du service
enum ChatStatus {
  idle,          // pas encore chargé
  loading,       // chargement en cours
  notLoggedIn,   // utilisateur non connecté
  offline,       // serveur injoignable
  emptyOnline,   // connecté, personne en ligne
  ready,         // connecté + utilisateurs en ligne
}

class ChatService {
  ChatService._private();
  static final ChatService instance = ChatService._private();

  // ==========================================
  // ÉTAT
  // ==========================================
  ChatStatus _status = ChatStatus.idle;
  ChatStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ChatUser> _contacts = [];
  List<ChatUser> get contacts => List.unmodifiable(_contacts);

  List<ChatUser> get onlineContacts =>
      _contacts.where((c) => c.isOnline).toList();

  final Map<String, List<Message>> _messages = {};

  // ==========================================
  // SIMULATION (à remplacer par l'API)
  // ==========================================
  // 👉 Change ce mode pour tester les différents cas :
  //    'normal'      → connecté + utilisateurs en ligne
  //    'empty'       → connecté mais personne en ligne
  //    'offline'     → serveur injoignable
  //    'notLogged'   → non connecté
  String debugMode = 'normal';

  // ==========================================
  // CHARGEMENT
  Future<void> loadChat({
  required bool isLoggedIn,
}) async {
  _status = ChatStatus.loading;
  _errorMessage = null;

  // ==========================================
  // 1. NON CONNECTÉ
  // ==========================================
  if (!isLoggedIn || debugMode == 'notLogged') {
    await Future.delayed(const Duration(milliseconds: 300));
    _status = ChatStatus.notLoggedIn;
    _contacts = [];
    return;
  }

  // ==========================================
  // 2. APPEL AVEC TIMEOUT DE 5 SECONDES
  // ==========================================
  try {
    // 👉 Simulation d'un appel réseau (à remplacer par http.get)
    // Ce Future.delayed représente ce que fera ton vrai appel API.
    await Future.delayed(const Duration(milliseconds: 800))
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    // 👉 Timeout atteint ou erreur réseau
    _status = ChatStatus.offline;
    _errorMessage =
        "Désolé, le serveur met trop de temps à répondre. Réessayez plus tard.";
    _contacts = [];
    return;
  }

  // ==========================================
  // 3. SERVEUR INJOIGNABLE (simulé)
  // ==========================================
  if (debugMode == 'offline') {
    _status = ChatStatus.offline;
    _errorMessage =
        "Désolé, le serveur est injoignable. Réessayez plus tard.";
    _contacts = [];
    return;
  }

  // ==========================================
  // 4. PERSONNE EN LIGNE (simulé)
  // ==========================================
  if (debugMode == 'empty') {
    _contacts = [
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
    _status = ChatStatus.emptyOnline;
    return;
  }

  // ==========================================
  // 5. TOUT EST OK
  // ==========================================
  _contacts = [
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
  _status = ChatStatus.ready;
}
 


  // ==========================================
  // MESSAGES
  // ==========================================
  List<Message> getMessages(String otherUserId) {
    return _messages[otherUserId] ?? [];
  }

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