import 'package:flutter/material.dart';
import 'package:rundi_go/features/others/shop/category_places_screen.dart';

class SchoolsScreen extends StatelessWidget {
  const SchoolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryPlacesScreen(
      title: "Écoles",
      keywords: [
        'ecole',
        'école',
        'université',
        'universite',
        'lycée',
        'lycee',
        'college',
        'collège'
      ],
      icon: Icons.school,
      color: Color(0xFF3949AB),
    );
  }
}