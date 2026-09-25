class ChatUser {
  final String id;
  final String username;
  final String fullName;
  final String photoUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  ChatUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.photoUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'].toString(),
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      photoUrl: json['photo'] as String? ?? '',
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
    );
  }
}