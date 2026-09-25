class Story {
  final String id;
  final String title;      // Titre en Kirundi
  final String titleFr;    // Titre en Français (pour comprendre)
  final String content;    // Histoire complète en Kirundi
  final String imageUrl;   // Illustration
  final String duration;   // Durée estimée

  Story({
    required this.id,
    required this.title,
    required this.titleFr,
    required this.content,
    required this.imageUrl,
    required this.duration,
  });
}