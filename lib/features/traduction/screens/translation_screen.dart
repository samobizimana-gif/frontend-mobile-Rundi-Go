import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rundi_go/core/config.dart';
import 'package:rundi_go/services/translation_services.dart';

import '../../../core/api_client.dart';
import '../../../core/app_toast.dart';
import '../../../core/error_helper.dart';
import '../../../services/audio_service.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  int _activeTab = 0; // 0=Texte, 1=Image, 2=Conversation

  final List<Map<String, String>> _languages = AppConfig.supportedLanguages;

  String _sourceCode = 'fr';
  String _targetCode = 'sw';

  final TextEditingController _inputController = TextEditingController();
  final int _maxChars = 500;

  String _translatedText = '';
  String _detectedText = '';
  String _detectedSource = '';
  bool _hasTranslation = false;

  // Image
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessingImage = false;

  // Enregistrement
  bool _isRecording = false;
  bool _isTranscribing = false;

  @override
  void dispose() {
    _inputController.dispose();
    AudioService.instance.stopPlayback();
    super.dispose();
  }

  // ==========================================
  // 🌐 TRADUCTION TEXTE
  // ==========================================
  Future<void> _translateText() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      AppToast.error(context, "Veuillez entrer du texte");
      return;
    }

    setState(() {
      _hasTranslation = false;
      _translatedText = '';
      _detectedText = '';
      _detectedSource = '';
    });

    try {
      try {
        final det = await TranslationService.instance.detectLanguage(input);
        if (det['detected'] == true && det['language'] != null) {
          _detectedSource = det['language'].toString();
        }
      } catch (_) {}

      final res = await TranslationService.instance.translate(
        text: input,
        sourceLang: _sourceCode,
        targetLang: _targetCode,
      );

      if (!mounted) return;
      setState(() {
        _translatedText = res['translated_text'] ?? '';
        _hasTranslation = true;
      });
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } on NetworkException catch (e) {
      if (mounted) showApiError(context, e);
    } catch (e) {
      if (mounted) AppToast.error(context, "Erreur : $e");
    }
  }

  // ==========================================
  // 🔊 TTS — LIRE LA TRADUCTION
  // ==========================================
  Future<void> _speakTranslation() async {
    if (_translatedText.isEmpty) return;

    if (!TranslationService.instance.isTtsSupported(_targetCode)) {
      AppToast.warning(context, "Voix non disponible pour cette langue");
      return;
    }

    final url = TranslationService.instance.ttsUrl(
      text: _translatedText,
      lang: _targetCode,
    );
    await AudioService.instance.playUrl(url);
  }

  // ==========================================
  // 🎤 ENREGISTREMENT (ASR)
  // ==========================================
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Arrêter
      final file = await AudioService.instance.stopRecording();
      setState(() => _isRecording = false);

      if (file == null) return;

      setState(() => _isTranscribing = true);
      try {
        final res = await TranslationService.instance.transcribeAudio(
          audio: file,
          lang: _sourceCode,
        );
        if (!mounted) return;
        setState(() {
          _inputController.text = res['text'] ?? '';
          _isTranscribing = false;
        });
        await _translateText();
      } on ApiException catch (e) {
        if (mounted) {
          setState(() => _isTranscribing = false);
          AppToast.error(context,
              e.statusCode == 422 ? "Aucune parole détectée" : e.message);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isTranscribing = false);
          AppToast.error(context, "Erreur : $e");
        }
      }
    } else {
      // Démarrer
      final ok = await AudioService.instance.startRecording();
      if (!ok) {
        AppToast.error(context, "Permission micro refusée");
        return;
      }
      setState(() => _isRecording = true);
    }
  }

  // ==========================================
  // 📸 OCR
  // ==========================================
  Future<void> _pickImage(ImageSource source) async {
  try {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70,        // 👈 compression
      maxWidth: 1200,          // 👈 redimensionnement
      maxHeight: 1200,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null) return;

    final file = File(picked.path);

    // 👉 Vérifie la taille
    final sizeKb = await file.length() ~/ 1024;
    print("🐛 Image OCR : ${file.path} ($sizeKb Ko)");
    if (sizeKb > 8000) {
      AppToast.error(context, "Image trop lourde (>8 Mo)");
      return;
    }

    setState(() {
      _selectedImage = file;
      _hasTranslation = false;
      _translatedText = '';
      _detectedText = '';
    });

    _runOcrTranslate();
  } catch (e) {
    AppToast.error(context, "Erreur : $e");
  }
}



  Future<void> _runOcrTranslate() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessingImage = true);
    try {
      final res = await TranslationService.instance.translateImage(
        image: _selectedImage!,
        targetLang: _targetCode,
      );
      if (!mounted) return;
      setState(() {
        _detectedText = res['extracted_text'] ?? '';
        _translatedText = res['translated_text'] ?? '';
        _detectedSource = res['source_lang'] ?? '';
        _hasTranslation = true;
        _isProcessingImage = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _isProcessingImage = false);
        AppToast.error(context,
            e.statusCode == 422 ? "Aucun texte détecté" : e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingImage = false);
        AppToast.error(context, "Erreur : $e");
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _hasTranslation = false;
      _translatedText = '';
      _detectedText = '';
      _detectedSource = '';
    });
  }

  // ==========================================
  // UTILS
  // ==========================================
  void _pickLanguage({required bool isSource}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(isSource ? "Langue source" : "Langue cible",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _languages.length,
                itemBuilder: (context, i) {
                  final lang = _languages[i];
                  final current = isSource ? _sourceCode : _targetCode;
                  final selected = current == lang['code'];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF1E88E5).withOpacity(0.15)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        lang['code']!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: selected
                              ? const Color(0xFF1E88E5)
                              : Colors.grey,
                        ),
                      ),
                    ),
                    title: Text(lang['label']!,
                        style: TextStyle(
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected
                              ? const Color(0xFF1E88E5)
                              : Colors.black87,
                        )),
                    trailing: selected
                        ? const Icon(Icons.check, color: Color(0xFF1E88E5))
                        : null,
                    onTap: () {
                      setState(() {
                        if (isSource) {
                          _sourceCode = lang['code']!;
                        } else {
                          _targetCode = lang['code']!;
                        }
                        _hasTranslation = false;
                        _translatedText = '';
                        _detectedText = '';
                        _detectedSource = '';
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}


  void _swapLanguages() {
    setState(() {
      final t = _sourceCode;
      _sourceCode = _targetCode;
      _targetCode = t;
      _hasTranslation = false;
      _translatedText = '';
      _detectedText = '';
      _detectedSource = '';
    });
  }

  void _copyResult() {
    Clipboard.setData(ClipboardData(text: _translatedText));
    AppToast.success(context, "Copié");
  }

  String _labelOf(String code) {
    return _languages.firstWhere((l) => l['code'] == code,
        orElse: () => {'label': code})['label']!;
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text("Traduction",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTabs(),
              const SizedBox(height: 20),
              _buildLanguageSelectors(),
              const SizedBox(height: 20),

              if (_activeTab == 0)
                _buildTextSection()
              else if (_activeTab == 1)
                _buildImageSection()
              else
                _buildConversationPlaceholder(),

              const SizedBox(height: 20),
              if (_hasTranslation && _detectedText.isNotEmpty)
                _buildDetectedTextCard(),
              if (_hasTranslation) _buildResultCard(),
              if (_hasTranslation) _buildDetectedLanguages(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ONGLETS
  // ==========================================
  Widget _buildTabs() {
    final tabs = ['Texte', 'Image', 'Conversation'];
    return Row(
      children: List.generate(tabs.length, (i) {
        final active = _activeTab == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
            child: GestureDetector(
              onTap: () => setState(() {
                _activeTab = i;
                _hasTranslation = false;
                _translatedText = '';
                _detectedText = '';
              }),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF1E88E5) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? const Color(0xFF1E88E5)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Text(tabs[i],
                    style: TextStyle(
                      color: active ? Colors.white : Colors.black87,
                      fontWeight:
                          active ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    )),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ==========================================
  // SÉLECTEURS
  // ==========================================
  Widget _buildLanguageSelectors() {
    return Row(
      children: [
        Expanded(child: _langBox(_sourceCode, true)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GestureDetector(
            onTap: _swapLanguages,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.swap_horiz,
                  size: 20, color: Color(0xFF1E88E5)),
            ),
          ),
        ),
        Expanded(child: _langBox(_targetCode, false)),
      ],
    );
  }

  Widget _langBox(String code, bool isSource) {
    return GestureDetector(
      onTap: () => _pickLanguage(isSource: isSource),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_labelOf(code),
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            const Icon(Icons.keyboard_arrow_down,
                color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TEXTE
  // ==========================================
  Widget _buildTextSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              TextField(
                controller: _inputController,
                maxLines: 5,
                maxLength: _maxChars,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  hintText: "Bonjour, comment ça va ?",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
              Row(
                children: [
                  // 🎤 Micro
                  GestureDetector(
                    onTap: _isTranscribing ? null : _toggleRecording,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? Colors.red.withOpacity(0.15)
                            : _isTranscribing
                                ? Colors.grey.withOpacity(0.15)
                                : const Color(0xFFE3F2FD),
                        shape: BoxShape.circle,
                      ),
                      child: _isTranscribing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1E88E5)),
                            )
                          : Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: _isRecording
                                  ? Colors.red
                                  : const Color(0xFF1E88E5),
                              size: 22,
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_isRecording)
                    const Text("Enregistrement...",
                        style: TextStyle(
                            fontSize: 12, color: Colors.red)),
                  if (_isTranscribing)
                    const Text("Transcription...",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  const Spacer(),
                  Text("${_inputController.text.length}/$_maxChars",
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _translateText,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text("Traduire",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // IMAGE
  // ==========================================
  Widget _buildImageSection() {
    if (_selectedImage == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_photo_alternate_outlined,
                  size: 50, color: Color(0xFF1E88E5)),
            ),
            const SizedBox(height: 20),
            const Text("Ajoutez une image à traduire",
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              "Le texte sera extrait automatiquement puis traduit.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text("Galerie",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text("Caméra",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E88E5),
                  side: const BorderSide(
                      color: Color(0xFF1E88E5), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ),
            ],
          ),
          if (_isProcessingImage) ...[
            const SizedBox(height: 15),
            const Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                    color: Color(0xFF1E88E5), strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Analyse de l'image...",
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // CONVERSATION
  // ==========================================
  Widget _buildConversationPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mic_none,
                size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          const Text("Conversation",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "La traduction vocale en temps réel arrive bientôt.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARTES RÉSULTAT
  // ==========================================
  Widget _buildDetectedTextCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.text_fields,
                    color: Color(0xFFFB8C00), size: 16),
              ),
              const SizedBox(width: 8),
              const Text("Texte détecté",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFB8C00))),
            ],
          ),
          const SizedBox(height: 12),
          Text(_detectedText,
              style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final canSpeak =
        TranslationService.instance.isTtsSupported(_targetCode);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_translatedText,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ),
              if (canSpeak)
                GestureDetector(
                  onTap: _speakTranslation,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.volume_up,
                        color: Color(0xFF1E88E5), size: 26),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_labelOf(_targetCode),
                    style: const TextStyle(
                        color: Color(0xFF1E88E5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _copyResult,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child:
                      Icon(Icons.copy, color: Colors.grey, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedLanguages() {
    if (_detectedSource.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Langues détectées",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text("${_labelOf(_detectedSource)} (source)",
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child:
                    Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
              ),
              Text(_labelOf(_targetCode),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5))),
            ],
          ),
        ],
      ),
    );
  }
}