import 'public_user.dart';

class FriendRequest {
  final int id;
  final PublicUser fromUser;
  final PublicUser toUser;
  final String status; // 'pending', 'accepted', 'rejected', 'cancelled'
  final String createdAt;

  FriendRequest({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      fromUser: PublicUser.fromJson(
          Map<String, dynamic>.from(json['from_user'] ?? {})),
      toUser: PublicUser.fromJson(
          Map<String, dynamic>.from(json['to_user'] ?? {})),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}