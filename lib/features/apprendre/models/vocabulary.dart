class VocabularyWord {
  final String original;   // Mot dans la langue source
  final String kirundi;    // Traduction en Kirundi
  final String category;   // Salutations, Nourriture, etc.

  VocabularyWord({
    required this.original,
    required this.kirundi,
    required this.category,
  });
}