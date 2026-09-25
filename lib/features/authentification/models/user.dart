import 'package:rundi_go/core/config.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;                // touriste | gerant | admin
  final String managerStatus;       // none | pending_payment | active | expired
  final String? subscriptionExpiresAt;
  final String languagePreferee;
  final String langue;
  final String country;
  final String? photo;
  final String? photoUrl;
  final String phone;
  final String bio;
  final String? dateJoined;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.managerStatus = 'none',
    this.subscriptionExpiresAt,
    required this.languagePreferee,
    required this.langue,
    required this.country,
    this.photo,
    this.photoUrl,
    this.phone = '',
    this.bio = '',
    this.dateJoined,
  });

  String get fullName {
    final f = '$firstName $lastName'.trim();
    return f.isEmpty ? username : f;
  }

  bool get isAdmin => role == 'admin';
  bool get isGerant => role == 'gerant';
  bool get hasActiveSubscription => managerStatus == 'active';

  /// 👉 Construit une URL utilisable pour Image.network
String? get displayPhoto {
  // Priorité à photoUrl
  if (photoUrl != null && photoUrl!.isNotEmpty) {
    return _cleanUrl(photoUrl!);
  }
  if (photo != null && photo!.isNotEmpty) {
    return _cleanUrl(photo!);
  }
  return null;
}

/// 👉 Transforme "file:///media/..." en "http://<backend>/media/..."
String _cleanUrl(String url) {
  // Si c'est déjà http:// ou https://, on garde
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  // Si c'est file:// ou /media/... → construire une URL backend
  final path = url
      .replaceFirst('file://', '')
      .replaceFirst(RegExp(r'^/*'), '/'); // enlève les / en trop

  return '${AppConfig.geoBaseUrl.replaceFirst('/api', '')}$path';
}

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'touriste',
      managerStatus: json['manager_status']?.toString() ?? 'none',
      subscriptionExpiresAt: json['subscription_expires_at']?.toString(),
      languagePreferee: json['language_preferee']?.toString() ?? 'fr',
      langue: json['langue']?.toString() ?? 'Français',
      country: json['country']?.toString() ?? 'bi',
      photo: json['photo']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      phone: json['phone']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      dateJoined: json['date_joined']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'language_preferee': languagePreferee,
        'country': country,
        'phone': phone,
        'bio': bio,
      };
}