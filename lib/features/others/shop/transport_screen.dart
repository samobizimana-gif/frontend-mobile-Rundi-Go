import 'package:flutter/material.dart';
import 'package:rundi_go/features/others/shop/category_places_screen.dart';

class TransportScreen extends StatelessWidget {
  const TransportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryPlacesScreen(
      title: "Transport",
      keywords: ['transport', 'gare', 'taxi', 'bus', 'aeroport', 'aéroport'],
      icon: Icons.local_taxi,
      color: Color(0xFF00897B),
    );
  }
}