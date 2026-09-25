import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:rundi_go/features/map/models/place.dart';
import 'package:rundi_go/features/map/screens/place_detail_screen.dart';
import '../../../core/api_client.dart';
import '../../../services/place_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 👉 Centre par défaut : Bujumbura
  static const LatLng _defaultCenter = LatLng(-3.3820, 29.3620);

  final MapController _mapController = MapController();

  // 👉 Vue : 0 = Standard, 1 = Relief, 2 = Sombre
  int _mapView = 0;

  final List<Map<String, String>> _mapViews = const [
    {
      'label': 'Standard',
      'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      'icon': 'map',
    },
    {
      'label': 'Relief',
      'url': 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
      'icon': 'terrain',
    },
    {
      'label': 'Sombre',
      'url':
          'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}.png',
      'icon': 'dark',
    },
  ];

  // 👉 État
  bool _isLoading = true;
  String? _error;
  List<Place> _places = [];

  // 👉 Position utilisateur
  LatLng? _userPosition;
  bool _isLoadingLocation = false;

  // 👉 Lieu sélectionné
  Place? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  // ==========================================
  // 📥 CHARGEMENT DES LIEUX
  // ==========================================
  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Place> places;
      if (_userPosition != null) {
        places = await PlaceService.instance.getNearby(
          lat: _userPosition!.latitude,
          lng: _userPosition!.longitude,
          radiusKm: 20,
        );
      } else {
        places = await PlaceService.instance.getAllPlaces();
      }

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
  // 🎯 ICÔNE / COULEUR PAR CATÉGORIE
  // ==========================================
  IconData _iconFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('hotel') || c.contains('hôtel')) return Icons.hotel;
    if (c.contains('resto')) return Icons.restaurant;
    if (c.contains('cafe') || c.contains('café')) return Icons.local_cafe;
    if (c.contains('hopital') ||
        c.contains('hôpital') ||
        c.contains('sant')) {
      return Icons.local_hospital;
    }
    if (c.contains('eglise') || c.contains('église')) return Icons.church;
    if (c.contains('parc') || c.contains('nature')) return Icons.park;
    if (c.contains('shop') || c.contains('march')) return Icons.shopping_bag;
    if (c.contains('transport') || c.contains('gare')) return Icons.local_taxi;
    if (c.contains('ecole') || c.contains('école')) return Icons.school;
    if (c.contains('musee') || c.contains('musée')) return Icons.museum;
    return Icons.location_on;
  }

  Color _colorFor(String category) {
    final c = category.toLowerCase();
    if (c.contains('hotel') || c.contains('hôtel')) {
      return const Color(0xFF1E88E5);
    }
    if (c.contains('resto')) return const Color(0xFFFB8C00);
    if (c.contains('cafe') || c.contains('café')) {
      return const Color(0xFF6D4C41);
    }
    if (c.contains('hopital') ||
        c.contains('hôpital') ||
        c.contains('sant')) {
      return Colors.red;
    }
    if (c.contains('eglise') || c.contains('église')) {
      return const Color(0xFF8E24AA);
    }
    if (c.contains('parc') || c.contains('nature')) {
      return const Color(0xFF43A047);
    }
    if (c.contains('shop') || c.contains('march')) {
      return const Color(0xFF8E24AA);
    }
    if (c.contains('transport')) return const Color(0xFF00897B);
    if (c.contains('ecole')) return const Color(0xFF3949AB);
    return Colors.grey;
  }

  // ==========================================
  // 📍 GPS
  // ==========================================
  Future<void> _goToUserPosition() async {
    setState(() => _isLoadingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _snack("Veuillez activer le GPS de votre téléphone.");
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _snack("Permission de localisation refusée.");
          setState(() => _isLoadingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _snack("Permission refusée définitivement.");
        setState(() => _isLoadingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLatLng = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _userPosition = userLatLng;
        _isLoadingLocation = false;
      });

      _mapController.move(userLatLng, 15);
      await _loadPlaces();
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _snack("Erreur GPS : $e");
    }
  }

  void _recenter() => _mapController.move(_defaultCenter, 13.5);

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  // ==========================================
  // 🎨 CHOISIR VUE
  // ==========================================
  void _openMapViewSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Type de vue",
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ...List.generate(_mapViews.length, (i) {
                final v = _mapViews[i];
                final selected = _mapView == i;
                return ListTile(
                  leading: Icon(
                    _iconForView(v['icon']!),
                    color:
                        selected ? const Color(0xFF1E88E5) : Colors.grey,
                  ),
                  title: Text(v['label']!),
                  trailing: selected
                      ? const Icon(Icons.check, color: Color(0xFF1E88E5))
                      : null,
                  onTap: () {
                    setState(() => _mapView = i);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  IconData _iconForView(String key) {
    switch (key) {
      case 'terrain':
        return Icons.terrain;
      case 'dark':
        return Icons.dark_mode;
      default:
        return Icons.map;
    }
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // CARTE
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 13.5,
                minZoom: 5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: _mapViews[_mapView]['url'],
                  userAgentPackageName: 'com.example.rundi_go',
                ),

                // MARQUEURS
                MarkerLayer(
                  markers: _places.map((place) {
                    final color = _colorFor(place.categorieNom);
                    final icon = _iconFor(place.categorieNom);
                    final isSelected = _selectedPlace?.id == place.id;

                    return Marker(
                      point: place.position,
                      width: isSelected ? 52 : 44,
                      height: isSelected ? 52 : 44,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedPlace = place);
                          _mapController.move(place.position, 15);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(icon,
                              color: Colors.white,
                              size: isSelected ? 26 : 22),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // MARQUEUR UTILISATEUR
                if (_userPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _userPosition!,
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E88E5)
                                    .withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // CHARGEMENT
            if (_isLoading)
              const Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text("Chargement des lieux..."),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ERREUR
            if (_error != null && !_isLoading)
              Positioned(
                top: 80,
                left: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade400),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(fontSize: 13)),
                      ),
                      TextButton(
                        onPressed: _loadPlaces,
                        child: const Text("Réessayer"),
                      ),
                    ],
                  ),
                ),
              ),

            // BOUTONS
            Positioned(
              top: 15,
              right: 15,
              child: Column(
                children: [
                  _mapButton(
                    icon: Icons.my_location,
                    loading: _isLoadingLocation,
                    onTap: _goToUserPosition,
                    color: const Color(0xFF1E88E5),
                  ),
                  const SizedBox(height: 10),
                  _mapButton(
                    icon: Icons.location_city,
                    onTap: _recenter,
                    color: const Color(0xFFFB8C00),
                  ),
                  const SizedBox(height: 10),
                  _mapButton(
                    icon: Icons.tune,
                    onTap: _openMapViewSheet,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),

            // CARTE INFO
            if (_selectedPlace != null)
              Positioned(
                bottom: 20,
                left: 15,
                right: 15,
                child: _buildPlaceInfoCard(_selectedPlace!),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // BOUTON ROND
  // ==========================================
  Widget _mapButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black87,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
          ],
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: color, size: 24),
      ),
    );
  }

  // ==========================================
  // CARTE INFO LIEU
  // ==========================================
  Widget _buildPlaceInfoCard(Place place) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: (place.imgUrl != null && place.imgUrl!.isNotEmpty)
                    ? Image.network(
                        place.imgUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgPlaceholder(),
                      )
                    : _imgPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.nom,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.categorieNom,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF1E88E5)),
                    ),
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
              GestureDetector(
                onTap: () => setState(() => _selectedPlace = null),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child:
                      Icon(Icons.close, color: Colors.grey, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PlaceDetailScreen(placeId: place.id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text("Voir détails",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _snack("Itinéraire (à venir)"),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text("Itinéraire",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E88E5),
                    side: const BorderSide(color: Color(0xFF1E88E5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image, color: Colors.grey, size: 30),
    );
  }
}