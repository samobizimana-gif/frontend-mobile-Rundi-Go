import 'package:flutter/material.dart';
import 'package:rundi_go/features/others/shop/category_places_screen.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CategoryPlacesScreen(
      title: "Shopping",
      keywords: ['shop', 'march', 'boutique', 'market'],
      icon: Icons.shopping_bag,
      color: Color(0xFF8E24AA),
    );
  }
}