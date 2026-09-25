import 'public_user.dart';

class Conversation {
  final int id;
  final String name;
  final List<PublicUser> participants;
  final String? lastMessage;
  final String createdAt;
  final String updatedAt;

  Conversation({
    required this.id,
    required this.name,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  // 👉 Nom affiché : si le groupe a un nom, on le prend.
  // Sinon, on concatène les prénoms des autres participants.
  String displayName(int myId) {
    if (name.trim().isNotEmpty) return name;
    final others =
        participants.where((p) => p.id != myId).toList();
    if (others.isEmpty) return "Conversation";
    return others.map((p) => p.firstName.isNotEmpty ? p.firstName : p.username).join(', ');
  }

  // 👉 Autres participants (excluant moi)
  List<PublicUser> others(int myId) =>
      participants.where((p) => p.id != myId).toList();

  // 👉 Premier autre participant (utile pour chat 1-à-1)
  PublicUser? firstOther(int myId) {
    final o = others(myId);
    return o.isEmpty ? null : o.first;
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // 👉 participants peut arriver en plusieurs formats :
    //    - List<Map> complet
    //    - Liste d'ids (rare)
    List<PublicUser> parts = [];
    final raw = json['participants'];
    if (raw is List) {
      for (final p in raw) {
        if (p is Map) {
          parts.add(PublicUser.fromJson(Map<String, dynamic>.from(p)));
        }
      }
    }

    // 👉 Parfois le backend envoie other_participants
    final others = json['other_participants'];
    if (parts.isEmpty && others is List) {
      for (final p in others) {
        if (p is Map) {
          parts.add(PublicUser.fromJson(Map<String, dynamic>.from(p)));
        }
      }
    }

    return Conversation(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      participants: parts,
      lastMessage: json['last_message']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}