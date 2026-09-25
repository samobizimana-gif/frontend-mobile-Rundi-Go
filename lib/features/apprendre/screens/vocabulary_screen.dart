import 'package:flutter/material.dart';
import 'package:rundi_go/features/apprendre/data/vocabulary_data.dart';
import 'package:rundi_go/features/apprendre/models/vocabulary.dart';
import 'package:rundi_go/features/apprendre/services/tts_service.dart';


class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  int? _flippedIndex;
  int? _speakingIndex;

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _onWordTap(int index, VocabularyWord word) async {
    // 👉 Clic 1 : afficher le Kirundi
    if (_flippedIndex != index) {
      setState(() {
        _flippedIndex = index;
        _speakingIndex = null;
      });
      return;
    }

    // 👉 Clic 2 : lire en Kirundi
    setState(() => _speakingIndex = index);
    await TtsService.instance.speak(word.kirundi);

    // 👉 Après la lecture, retour au mot original
    if (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _flippedIndex = null;
          _speakingIndex = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Vocabulaire",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 👉 Info
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, color: Color(0xFF1E88E5), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Touchez un mot pour voir sa traduction, touchez encore pour l'écouter.",
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            // 👉 GRILLE
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: vocabulary.length,
                itemBuilder: (context, i) {
                  final word = vocabulary[i];
                  final isFlipped = _flippedIndex == i;
                  final isSpeaking = _speakingIndex == i;

                  return GestureDetector(
                    onTap: () => _onWordTap(i, word),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isFlipped
                            ? const Color(0xFF1E88E5)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                          ),
                        ],
                        border: isSpeaking
                            ? Border.all(
                                color: const Color(0xFF4CAF50), width: 3)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isFlipped ? word.kirundi : word.original,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isFlipped
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (isSpeaking)
                            const Icon(Icons.volume_up,
                                color: Colors.white, size: 18)
                          else if (isFlipped)
                            const Icon(Icons.volume_up,
                                color: Colors.white70, size: 16)
                          else
                            Text(
                              word.category,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}