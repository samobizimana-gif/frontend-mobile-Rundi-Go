import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService._private();
  static final TtsService instance = TtsService._private();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;

    // 👉 Essaie plusieurs langues dans l'ordre de préférence
    // Le Kirundi n'est pas supporté nativement, on essaie :
    // 1. Kirundi (rw)   → très rare
    // 2. Swahili (sw)   → proche linguistiquement
    // 3. Français (fr)  → fallback
    final langs = ['rw', 'sw-KE', 'sw', 'fr-FR'];

    for (final lang in langs) {
      try {
        final result = await _tts.setLanguage(lang);
        if (result == 1) break;
      } catch (_) {}
    }

    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _initialized = true;
  }

  Future<void> speak(String text) async {
    await _init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}