import 'public_user.dart';

class ChatMessage {
  final int id;
  final int conversationId;
  final PublicUser sender;
  final String messageType; // 'text' | 'voice'
  final String? originalText;
  final String? originalLang;
  final String? displayText;   // 👈 traduit pour MOI
  final String? displayLang;
  final String? translationStatus; // pending | done | skipped | error
  final String? transcriptionStatus; // pending | done | error
  final String? audioUrl;
  final int? durationSeconds;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.messageType,
    this.originalText,
    this.originalLang,
    this.displayText,
    this.displayLang,
    this.translationStatus,
    this.transcriptionStatus,
    this.audioUrl,
    this.durationSeconds,
    required this.createdAt,
  });

  bool get isText => messageType == 'text';
  bool get isVoice => messageType == 'voice';

  /// 👉 Le texte à afficher : on privilégie la traduction
  String get textToShow => displayText ?? originalText ?? '';

  DateTime? get parsedDate {
    try {
      return DateTime.parse(createdAt);
    } catch (_) {
      return null;
    }
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      conversationId: json['conversation'] is int
          ? json['conversation']
          : int.tryParse('${json['conversation']}') ?? 0,
      sender: PublicUser.fromJson(
          Map<String, dynamic>.from(json['sender'] ?? {})),
      messageType: json['message_type']?.toString() ?? 'text',
      originalText: json['original_text']?.toString(),
      originalLang: json['original_lang']?.toString(),
      displayText: json['display_text']?.toString(),
      displayLang: json['display_lang']?.toString(),
      translationStatus: json['translation_status']?.toString(),
      transcriptionStatus: json['transcription_status']?.toString(),
      audioUrl: json['audio_url']?.toString(),
      durationSeconds: json['duration_seconds'] is int
          ? json['duration_seconds']
          : int.tryParse('${json['duration_seconds']}'),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}