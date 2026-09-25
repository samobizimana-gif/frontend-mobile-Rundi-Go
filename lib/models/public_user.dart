class PublicUser {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String role;
  final String languePreferee;
  final String country;
  final String? photo;
  final String? photoUrl;
  final String friendStatus; // 'none', 'outgoing', 'incoming', 'friends'

  PublicUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.languePreferee,
    required this.country,
    this.photo,
    this.photoUrl,
    required this.friendStatus,
  });

  String get fullName {
    final f = '$firstName $lastName'.trim();
    return f.isEmpty ? username : f;
  }

  String? get displayPhoto => photoUrl ?? photo;

  bool get isFriend => friendStatus == 'friends';
  bool get hasOutgoing => friendStatus == 'outgoing';
  bool get hasIncoming => friendStatus == 'incoming';
  bool get canSendRequest => friendStatus == 'none';

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    return PublicUser(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'touriste',
      languePreferee: json['langue_preferee']?.toString() ?? 'fr',
      country: json['country']?.toString() ?? '',
      photo: json['photo']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      friendStatus: json['friend_status']?.toString() ?? 'none',
    );
  }
}