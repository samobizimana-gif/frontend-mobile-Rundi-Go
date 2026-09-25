import 'package:flutter/material.dart';
import 'package:rundi_go/features/map/models/place.dart';
import '../../../core/api_client.dart';
import '../../../services/place_service.dart';

class AllPlacesScreen extends StatefulWidget {
  const AllPlacesScreen({super.key});

  @override
  State<AllPlacesScreen> createState() => _AllPlacesScreenState();
}

class _AllPlacesScreenState extends State<AllPlacesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PlaceService _placeService = PlaceService.instance;

  bool _isLoading = true;
  String? _error;
  List<Place> _places = [];
  String _selectedCategory = 'tous';

  // 👉 Catégories affichées en chips
  final List<Map<String, String>> _categories = const [
    {'key': 'tous', 'label': 'Tous'},
    {'key': 'hotel', 'label': 'Hôtels'},
    {'key': 'restaurant', 'label': 'Restaurants'},
    {'key': 'cafe', 'label': 'Cafés'},
    {'key': 'parc', 'label': 'Parcs'},
    {'key': 'hopital', 'label': 'Hôpitaux'},
    {'key': 'eglise', 'label': 'Églises'},
    {'key': 'shopping', 'label': 'Shopping'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // 📥 CHARGEMENT
  // ==========================================
  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final places = await _placeService.getAllPlaces();
      if (!mounted) return;
      setState(() {
        _places = places;
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

  // ==========================================
  // 🔍 RECHERCHE
  // ==========================================
  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) {
      _loadPlaces();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final places = await _placeService.search(query);
      if (!mounted) return;
      setState(() {
        _places = places;
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

  // ==========================================
  // 🎯 FILTRE LOCAL PAR CATÉGORIE
  // ==========================================
  List<Place> get _filteredPlaces {
    if (_selectedCategory == 'tous') return _places;
    return _places.where((p) {
      final c = p.categorieNom.toLowerCase();
      return c.contains(_selectedCategory) ||
          _selectedCategory.contains(c) ||
          c.contains(_categoryAlias(_selectedCategory));
    }).toList();
  }

  String _categoryAlias(String key) {
    switch (key) {
      case 'hotel':
        return 'hôtel';
      case 'cafe':
        return 'café';
      case 'hopital':
        return 'hôpital';
      case 'eglise':
        return 'église';
      default:
        return key;
    }
  }

  // ==========================================
  // 🎨 ICÔNES ET COULEURS
  // ==========================================
  IconData _iconFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('hotel') || c.contains('hôtel')) return Icons.hotel;
    if (c.contains('resto')) return Icons.restaurant;
    if (c.contains('cafe') || c.contains('café')) return Icons.local_cafe;
    if (c.contains('hopital') || c.contains('hôpital') || c.contains('sant')) {
      return Icons.local_hospital;
    }
    if (c.contains('eglise') || c.contains('église')) return Icons.church;
    if (c.contains('parc') || c.contains('nature')) return Icons.park;
    if (c.contains('shop') || c.contains('march')) return Icons.shopping_bag;
    return Icons.location_on;
  }

  Color _colorFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('hotel') || c.contains('hôtel')) return const Color(0xFF1E88E5);
    if (c.contains('resto')) return const Color(0xFFFB8C00);
    if (c.contains('cafe') || c.contains('café')) return const Color(0xFF6D4C41);
    if (c.contains('hopital') || c.contains('hôpital') || c.contains('sant')) {
      return Colors.red;
    }
    if (c.contains('eglise') || c.contains('église')) return const Color(0xFF8E24AA);
    if (c.contains('parc') || c.contains('nature')) return const Color(0xFF43A047);
    if (c.contains('shop') || c.contains('march')) return const Color(0xFF8E24AA);
    return Colors.grey;
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text("Tous les lieux",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 👉 BARRE DE RECHERCHE
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: _runSearch,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: "Rechercher un lieu...",
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _loadPlaces();
                        },
                        child: const Icon(Icons.close,
                            color: Colors.grey, size: 18),
                      ),
                  ],
                ),
              ),
            ),

            // 👉 CHIPS CATÉGORIES
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = cat['key']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF1E88E5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF1E88E5)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          cat['label']!,
                          style: TextStyle(
                            color:
                                selected ? Colors.white : Colors.black87,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // 👉 CONTENU
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1E88E5)),
            SizedBox(height: 15),
            Text("Chargement des lieux...",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 15),
              const Text("Impossible de charger les lieux",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadPlaces,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Réessayer"),
              ),
            ],
          ),
        ),
      );
    }

    final places = _filteredPlaces;

    if (places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 15),
            const Text("Aucun lieu trouvé",
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text("${places.length} lieu${places.length > 1 ? 'x' : ''}",
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: places.length,
            itemBuilder: (context, i) {
              final place = places[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlaceTile(place: place, onTap: () => _openDetail(place)),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openDetail(Place place) {
    // 👉 Plus tard : naviguer vers PlaceDetailScreen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Détails de ${place.nom} (Étape 4.3)")),
    );
  }
}

// ==========================================
// TUILE D'UN LIEU
// ==========================================
class _PlaceTile extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _PlaceTile({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (place.imgUrl != null && place.imgUrl!.isNotEmpty)
                  ? Image.network(
                      place.imgUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 15),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.nom,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(place.categorieNom,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF1E88E5))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.grey, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${place.distanceKm.toStringAsFixed(1)} km • ${place.ville}",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}