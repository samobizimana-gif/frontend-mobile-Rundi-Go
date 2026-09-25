import 'package:flutter/material.dart';
import 'package:rundi_go/features/map/models/place.dart';
import 'package:rundi_go/features/map/screens/place_detail_screen.dart';

import '../../../core/api_client.dart';
import '../../../core/error_helper.dart';
import '../../../services/place_service.dart';

class CategoryPlacesScreen extends StatefulWidget {
  final String title;
  final List<String> keywords;
  final IconData icon;
  final Color color;

  const CategoryPlacesScreen({
    super.key,
    required this.title,
    required this.keywords,
    required this.icon,
    required this.color,
  });

  @override
  State<CategoryPlacesScreen> createState() => _CategoryPlacesScreenState();
}

class _CategoryPlacesScreenState extends State<CategoryPlacesScreen> {
  bool _isLoading = true;
  String? _error;
  List<Place> _places = [];

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
      final all = await PlaceService.instance.getAllPlaces();

      // 👉 Filtre local par mots-clés
      final filtered = all.where((p) {
        final cat = p.categorieNom.toLowerCase();   // ✅ CORRIGÉ
        final nom = p.nom.toLowerCase();
        return widget.keywords.any((k) =>
            cat.contains(k.toLowerCase()) || nom.contains(k.toLowerCase()));
      }).toList();

      if (!mounted) return;
      setState(() {
        _places = filtered;
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

  void _openDetail(Place p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaceDetailScreen(placeId: p.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
              )
            : _error != null
                ? buildErrorState(message: _error!, onRetry: _load)
                : _places.isEmpty
                    ? buildEmptyState(
                        icon: widget.icon,
                        title: "Aucun lieu dans ${widget.title}",
                        subtitle:
                            "Revenez plus tard ou explorez la carte.",
                      )
                    : _buildList(),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _places.length,
      itemBuilder: (context, i) {
        final p = _places[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _openDetail(p),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  // Icône colorée
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon,
                        color: widget.color, size: 26),
                  ),
                  const SizedBox(width: 12),

                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nom,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(p.categorieNom,   // ✅ CORRIGÉ
                            style: TextStyle(
                                fontSize: 12, color: widget.color)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${p.distanceKm.toStringAsFixed(1)} km • ${p.ville}",
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Icon(Icons.chevron_right,
                      color: Colors.grey, size: 22),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}