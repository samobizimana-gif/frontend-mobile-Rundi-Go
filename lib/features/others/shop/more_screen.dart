import 'package:flutter/material.dart';
import 'package:rundi_go/features/map/models/place_category.dart';
import 'package:rundi_go/features/others/shop/category_places_screen.dart';

import '../../../core/api_client.dart';
import '../../../core/error_helper.dart';
import '../../../services/place_service.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  bool _isLoading = true;
  String? _error;
  List<PlaceCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await PlaceService.instance.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Erreur : $e";
        _isLoading = false;
      });
    }
  }

  IconData _iconFor(String nom) {
    final c = nom.toLowerCase();
    if (c.contains('hotel') || c.contains('hôtel')) return Icons.hotel;
    if (c.contains('resto')) return Icons.restaurant;
    if (c.contains('cafe') || c.contains('café')) return Icons.local_cafe;
    if (c.contains('sant') || c.contains('hopit')) {
      return Icons.local_hospital;
    }
    if (c.contains('eglise')) return Icons.church;
    if (c.contains('parc')) return Icons.park;
    if (c.contains('shop') || c.contains('march')) return Icons.shopping_bag;
    if (c.contains('transport')) return Icons.local_taxi;
    if (c.contains('ecole')) return Icons.school;
    if (c.contains('musee')) return Icons.museum;
    return Icons.place;
  }

  Color _colorFor(String nom) {
    final c = nom.toLowerCase();
    if (c.contains('hotel') || c.contains('hôtel')) {
      return const Color(0xFF1E88E5);
    }
    if (c.contains('resto')) return const Color(0xFFFB8C00);
    if (c.contains('cafe') || c.contains('café')) {
      return const Color(0xFF6D4C41);
    }
    if (c.contains('sant') || c.contains('hopit')) return Colors.red;
    if (c.contains('eglise')) return const Color(0xFF8E24AA);
    if (c.contains('parc')) return const Color(0xFF43A047);
    if (c.contains('shop') || c.contains('march')) {
      return const Color(0xFF8E24AA);
    }
    if (c.contains('transport')) return const Color(0xFF00897B);
    if (c.contains('ecole')) return const Color(0xFF3949AB);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text("Plus",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
              )
            : _error != null
                ? buildErrorState(message: _error!, onRetry: _load)
                : _categories.isEmpty
                    ? buildEmptyState(
                        icon: Icons.category_outlined,
                        title: "Aucune catégorie",
                        subtitle: "Revenez plus tard.",
                      )
                    : _buildGrid(),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, i) {
        final cat = _categories[i];
        final color = _colorFor(cat.nom);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryPlacesScreen(
                  title: cat.nom,
                  keywords: [cat.nom],
                  icon: _iconFor(cat.nom),
                  color: color,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconFor(cat.nom), color: color, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  cat.nom,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}