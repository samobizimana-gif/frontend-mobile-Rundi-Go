import 'package:flutter/material.dart';
import 'package:rundi_go/features/map/models/place.dart';
import 'package:rundi_go/features/reservation/screens/create_reservation_screen.dart';
import '../../../core/api_client.dart';
import '../../../services/place_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDetailScreen extends StatefulWidget {
  final int placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Place? _place;
  List<Map<String, dynamic>> _menu = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final place = await PlaceService.instance.getPlaceDetail(widget.placeId);

      // 👉 Chargement du menu (silencieux si pas applicable)
      List<Map<String, dynamic>> menu = [];
      try {
        menu = await PlaceService.instance.getMenu(widget.placeId);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _place = place;
        _menu = menu;
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
  // ACTIONS
  // ==========================================
  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _snack("Impossible d'ouvrir : $url");
      }
    } catch (_) {
      _snack("Impossible d'ouvrir : $url");
    }
  }

  Future<void> _call(String phone) async {
    await _openUrl("tel:$phone");
  }

  Future<void> _sendEmail(String email) async {
    await _openUrl("mailto:$email");
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
              )
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 15),
            const Text("Impossible de charger le lieu",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
              ),
              child: const Text("Réessayer"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Retour"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final place = _place!;
    final hasImg = place.imgUrl != null && place.imgUrl!.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // IMAGE DE COUVERTURE
          // ==========================================
          Stack(
            children: [
              if (hasImg)
                Image.network(
                  place.imgUrl!,
                  width: double.infinity,
                  height: 260,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _coverPlaceholder(),
                )
              else
                _coverPlaceholder(),

              Positioned(
                top: 15,
                left: 15,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, size: 22),
                  ),
                ),
              ),
            ],
          ),

          // ==========================================
          // CONTENU
          // ==========================================
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom
                Text(place.nom,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Catégorie + Ville
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(place.categorieNom,
                          style: const TextStyle(
                              color: Color(0xFF1E88E5),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    if (place.ville.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(place.ville,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                    ],
                  ],
                ),

                // Adresse
                if (place.adresse != null && place.adresse!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(place.adresse!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ),
                    ],
                  ),
                ],

                // Distance
                if (place.distanceKm > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.near_me,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        "À ${place.distanceKm.toStringAsFixed(2)} km de vous",
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                // ACTIONS RAPIDES
                Row(
                  children: [
                    if (place.phone != null && place.phone!.isNotEmpty)
                      _quickAction(
                        icon: Icons.phone,
                        label: "Appeler",
                        color: const Color(0xFF4CAF50),
                        onTap: () => _call(place.phone!),
                      ),
                    if (place.email != null && place.email!.isNotEmpty)
                      _quickAction(
                        icon: Icons.email,
                        label: "Email",
                        color: const Color(0xFFFB8C00),
                        onTap: () => _sendEmail(place.email!),
                      ),
                    if (place.website != null && place.website!.isNotEmpty)
                      _quickAction(
                        icon: Icons.language,
                        label: "Site web",
                        color: const Color(0xFF8E24AA),
                        onTap: () => _openUrl(place.website!),
                      ),
                  ],
                ),

                const SizedBox(height: 25),

                // DESCRIPTION
                if (place.description != null &&
                    place.description!.isNotEmpty) ...[
                  const Text("Description",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8),
                      ],
                    ),
                    child: Text(place.description!,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87)),
                  ),
                  const SizedBox(height: 25),
                ],

                // GALERIE D'IMAGES
                if (place.images.isNotEmpty) ...[
                  const Text("Photos",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: place.images.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              place.images[i],
                              width: 160,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 160,
                                height: 120,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image,
                                    color: Colors.grey),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 25),
                ],

                // MENU
                if (_menu.isNotEmpty) ...[
                  const Text("Menu",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ..._menu.map((item) {
                    final available = item['is_available'] != false;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['nom']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: available
                                          ? Colors.black87
                                          : Colors.grey,
                                    )),
                                if (item['description'] != null &&
                                    '${item['description']}'.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('${item['description']}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey)),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "${item['prix'] ?? ''}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: available
                                  ? const Color(0xFF1E88E5)
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 15),
                ],

                // BOUTONS
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CreateReservationScreen(place: place),
    ),
  );
},
                    icon: const Icon(Icons.calendar_today, size: 20),
                    label: const Text("Réserver",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _snack("Itinéraire (à venir)"),
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text("Itinéraire",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E88E5),
                      side: const BorderSide(color: Color(0xFF1E88E5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      width: double.infinity,
      height: 260,
      color: const Color(0xFFE3F2FD),
      child:
          const Icon(Icons.image, size: 80, color: Color(0xFF1E88E5)),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}