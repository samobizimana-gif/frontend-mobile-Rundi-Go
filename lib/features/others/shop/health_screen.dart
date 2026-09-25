import 'package:flutter/material.dart';
import 'package:rundi_go/features/others/shop/category_places_screen.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryPlacesScreen(
      title: "Santé",
      keywords: [
        'hopital',
        'hôpital',
        'santé',
        'sante',
        'clinique',
        'pharmacie',
        'medical',
        'médical'
      ],
      icon: Icons.local_hospital,
      color: Colors.red,
    );
  }
}