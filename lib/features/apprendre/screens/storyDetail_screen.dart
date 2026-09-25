import 'package:flutter/material.dart';
import 'package:rundi_go/features/apprendre/models/story.dart';
import 'package:rundi_go/features/apprendre/services/tts_service.dart';


class StoryDetailScreen extends StatefulWidget {
  final Story story;

  const StoryDetailScreen({super.key, required this.story});

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  bool _isPlaying = false;

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await TtsService.instance.stop();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      await TtsService.instance.speak(widget.story.content);
      if (mounted) setState(() => _isPlaying = false);
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
          "Histoire",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👉 Image
              Image.network(
                widget.story.imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: const Color(0xFFFFF3E0),
                  child: const Icon(Icons.menu_book,
                      color: Color(0xFFFB8C00), size: 60),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.story.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.story.titleFr,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // 👉 Bouton ÉCOUTER
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: _togglePlay,
                        icon: Icon(
                          _isPlaying
                              ? Icons.stop_circle_outlined
                              : Icons.play_circle_outline,
                          size: 24,
                        ),
                        label: Text(
                          _isPlaying ? "Arrêter la lecture" : "Écouter",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPlaying
                              ? Colors.red.shade400
                              : const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 👉 Contenu
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        widget.story.content,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.7,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}