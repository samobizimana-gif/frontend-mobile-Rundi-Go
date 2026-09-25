import 'dart:io';

import '../core/api_client.dart';
import '../core/config.dart';

class TranslationService {
  TranslationService._private();
  static final TranslationService instance = TranslationService._private();

  // ==========================================
  // 🌐 TRADUIRE UN TEXTE
  // ==========================================
  Future<Map<String, dynamic>> translate({
    required String text,
    required String targetLang,
    String? sourceLang,
  }) async {
    final body = <String, dynamic>{
      'text': text,
      'target_lang': targetLang,
    };
    if (sourceLang != null) body['source_lang'] = sourceLang;

    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.langBaseUrl,
      path: '/translate',
      body: body,
      auth: false,
    );
    return Map<String, dynamic>.from(data);
  }

  // ==========================================
  // 🔍 DÉTECTER LA LANGUE
  // ==========================================
  Future<Map<String, dynamic>> detectLanguage(String text) async {
    final data = await ApiClient.instance.post(
      baseUrl: AppConfig.langBaseUrl,
      path: '/detect-or-none',
      body: {'text': text},
      auth: false,
    );
    return Map<String, dynamic>.from(data);
  }

  // ==========================================
  // 📸 OCR + TRADUCTION
  // ==========================================
  Future<Map<String, dynamic>> translateImage({
  required File image,
  required String targetLang,
  String? sourceLang,
}) async {
  final fields = <String, String>{'target_lang': targetLang};
  if (sourceLang != null) fields['source_lang'] = sourceLang;

  final data = await ApiClient.instance.uploadFile(
    baseUrl: AppConfig.langBaseUrl,
    path: '/ocr/translate',
    file: image,
    fileField: 'image',
    fields: fields,
    auth: false,
  );
  return Map<String, dynamic>.from(data);
}


  // ==========================================
  // 🎤 TRANSCRIPTION AUDIO (ASR)
  // ==========================================
  Future<Map<String, dynamic>> transcribeAudio({
    required File audio,
    String? lang,
  }) async {
    final fields = <String, String>{};
    if (lang != null) fields['lang'] = lang;

    final data = await ApiClient.instance.uploadFile(
      baseUrl: AppConfig.langBaseUrl,
      path: '/asr/transcribe',
      file: audio,
      fileField: 'audio',
      fields: fields,
      auth: false,
    );
    return Map<String, dynamic>.from(data);
  }

  // ==========================================
  // 🗣️ TTS — URL du MP3
  // ==========================================
  /// ⚠️ TTS supporte UNIQUEMENT : fr, en, sw
  String ttsUrl({required String text, required String lang}) {
    final encoded = Uri.encodeComponent(text);
    return '${AppConfig.langBaseUrl}/tts?text=$encoded&lang=$lang';
  }

  /// Vérifie si la langue est supportée pour TTS
  bool isTtsSupported(String lang) {
    return ['fr', 'en', 'sw'].contains(lang);
  }

  // ==========================================
  // 🎯 CONVERSATION — 1 tour
  // ==========================================
  Future<Map<String, dynamic>> conversationTurn({
    required File audio,
    required String sourceLang,
    required String targetLang,
  }) async {
    final data = await ApiClient.instance.uploadFile(
      baseUrl: AppConfig.langBaseUrl,
      path: '/conversation/turn',
      file: audio,
      fileField: 'audio',
      fields: {
        'source_lang': sourceLang,
        'target_lang': targetLang,
      },
      auth: false,
    );
    return Map<String, dynamic>.from(data);
  }
}