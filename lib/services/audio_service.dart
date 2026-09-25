import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService {
  AudioService._private();
  static final AudioService instance = AudioService._private();

  // ==========================================
  // 🔊 LECTURE MP3 (TTS)
  // ==========================================
  final AudioPlayer _player = AudioPlayer();

  /// Joue un MP3 depuis une URL (backend TTS)
  Future<void> playUrl(String url) async {
    try {
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      print("AudioService.playUrl error: $e");
    }
  }

  /// Arrête la lecture en cours
  Future<void> stopPlayback() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  // ==========================================
  // 🎤 ENREGISTREMENT (ASR)
  // ==========================================
  final AudioRecorder _recorder = AudioRecorder();

  /// Démarre un enregistrement. Retourne true si OK.
  Future<bool> startRecording() async {
  try {
    if (!await _recorder.hasPermission()) return false;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,   // 👈 WAV au lieu de AAC
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: path,
    );
    return true;
  } catch (e) {
    print("Erreur start: $e");
    return false;
  }
}


  /// Arrête l'enregistrement et retourne le fichier
  Future<File?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (path == null) return null;
      return File(path);
    } catch (e) {
      print("AudioService.stopRecording error: $e");
      return null;
    }
  }

  /// Vérifie si un enregistrement est en cours
  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (_) {
      return false;
    }
  }

  /// Libère les ressources
  Future<void> dispose() async {
    await _player.dispose();
    await _recorder.dispose();
  }
}