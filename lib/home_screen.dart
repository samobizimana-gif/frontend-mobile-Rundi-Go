import 'package:flutter/material.dart';
import 'package:rundi_go/features/apprendre/screens/learn_screen.dart';
import 'package:rundi_go/features/authentification/services/auth_service.dart';
import 'package:rundi_go/features/map/models/place.dart';
import 'package:rundi_go/features/map/screens/all_places_screen.dart';
import 'package:rundi_go/features/map/screens/map_screen.dart';
import 'package:rundi_go/features/map/screens/place_detail_screen.dart';
import 'package:rundi_go/features/others/payment/axchange_screen.dart';
import 'package:rundi_go/features/others/payment/pay_screen.dart';
import 'package:rundi_go/features/others/shop/category_places_screen.dart';
import 'package:rundi_go/features/others/shop/scanner_screen.dart';
import 'package:rundi_go/features/profilSettings/screens/profile_screen.dart';
import 'core/api_client.dart';
import 'core/app_toast.dart';
import 'services/place_service.dart';
import 'features/chat/screens/chat_screen.dart';

import 'features/traduction/screens/translation_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    _AccueilTab(onSwitchTab: (i) => setState(() => _currentIndex = i)),
    const MapScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Carte'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

// ==========================================
// ONGLET ACCUEIL
// ==========================================
class _AccueilTab extends StatefulWidget {
  final ValueChanged<int> onSwitchTab;
  const _AccueilTab({required this.onSwitchTab});

  @override
  State<_AccueilTab> createState() => _AccueilTabState();
}

class _AccueilTabState extends State<_AccueilTab> {
  final TextEditingController _searchController = TextEditingController();

  // 👉 État
  bool _isLoadingPlaces = true;
  String? _placesError;
  List<Place> _allPlaces = [];

  // 👉 Recherche et tri
  String _searchQuery = '';
  String _sortBy = 'nom'; // 'nom' | 'note' | 'distance'

  @override
  void initState() {
    super.initState();
    _loadPopularPlaces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // CHARGEMENT
  // ==========================================
  Future<void> _loadPopularPlaces() async {
    setState(() {
      _isLoadingPlaces = true;
      _placesError = null;
    });

    try {
      final places = await PlaceService.instance.getAllPlaces();

      if (!mounted) return;
      setState(() {
        _allPlaces = places;
        _isLoadingPlaces = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _placesError = e.message;
        _isLoadingPlaces = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _placesError = e.message;
        _isLoadingPlaces = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _placesError = "Erreur : $e";
        _isLoadingPlaces = false;
      });
    }
  }

  // ==========================================
  // FILTRE + TRI
  // ==========================================
  List<Place> get _displayedPlaces {
    List<Place> result = List.from(_allPlaces);

    // 👉 Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        return p.nom.toLowerCase().contains(q) ||
            p.categorieNom.toLowerCase().contains(q) ||
            p.ville.toLowerCase().contains(q);
      }).toList();
    }

    // 👉 Tri
    switch (_sortBy) {
      case 'note':
        // Pas de champ rating, on garde l'ordre original
        break;
      case 'distance':
        result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      default:
        result.sort((a, b) => a.nom.compareTo(b.nom));
    }

    return result;
  }

  String get _sortLabel {
    switch (_sortBy) {
      case 'distance':
        return 'Distance';
      case 'note':
        return 'Note';
      default:
        return 'Nom (A-Z)';
    }
  }

  // ==========================================
  // NAVIGATION
  // ==========================================
  void _push(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _goToAllPlaces() {
    _push(const AllPlacesScreen());
  }

  void _goToPlaceDetail(Place p) {
    _push(PlaceDetailScreen(placeId: p.id));
  }

  void _goToCategory({
    required String title,
    required List<String> keywords,
    required IconData icon,
    required Color color,
  }) {
    _push(CategoryPlacesScreen(
      title: title,
      keywords: keywords,
      icon: icon,
      color: color,
    ));
  }

  void _openMenuGrid(String label) {
    switch (label) {
      case 'Carte':
        widget.onSwitchTab(1);
        break;
      case 'Messagerie':
        widget.onSwitchTab(2);
        break;
      case 'Traduction':
        _push(const TranslationScreen());
        break;
      case 'Apprendre':
        _push(const LearnScreen());
        break;
      case 'Échange':
        _push(const ExchangeScreen());
        break;
      case 'Scanner':
        _push(const ScannerScreen());
        break;
      case 'Payer':
        _push(const PayScreen());
        break;
      case 'Plus':
        _openMoreSheet();
        break;
    }
  }

  // ==========================================
  // TRI
  // ==========================================
  void _openSortSheet() {
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
              const Text("Trier par",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _sortOption('nom', 'Nom (A-Z)', Icons.sort_by_alpha),
              _sortOption('distance', 'Plus proche', Icons.near_me),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _sortOption(String key, String label, IconData icon) {
    final selected = _sortBy == key;
    return ListTile(
      leading: Icon(icon,
          color: selected ? const Color(0xFF1E88E5) : Colors.grey),
      title: Text(label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? const Color(0xFF1E88E5) : Colors.black87,
          )),
      trailing: selected
          ? const Icon(Icons.check, color: Color(0xFF1E88E5))
          : null,
      onTap: () {
        setState(() => _sortBy = key);
        Navigator.pop(context);
      },
    );
  }

  // ==========================================
  // NOTIFICATIONS
  // ==========================================
  void _openNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
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
              const Text("Notifications",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.notifications_off_outlined,
                              size: 60, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 20),
                        const Text("Aucune notification",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                            "Vous n'avez aucune notification\npour le moment.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // SHEET PLUS
  // ==========================================
  void _openMoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
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
              const Text("Plus de fonctionnalités",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Services",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        children: [
                          _OptionTile(
                            icon: Icons.hotel,
                            label: 'Hôtels',
                            color: const Color(0xFF1E88E5),
                            onTap: () {
                              Navigator.pop(context);
                              _goToCategory(
                                title: "Hôtels",
                                keywords: ['hôt', 'hot', 'heberg', 'log'],
                                icon: Icons.hotel,
                                color: const Color(0xFF1E88E5),
                              );
                            },
                          ),
                          _OptionTile(
                            icon: Icons.restaurant,
                            label: 'Restaurants',
                            color: const Color(0xFFFB8C00),
                            onTap: () {
                              Navigator.pop(context);
                              _goToCategory(
                                title: "Restaurants",
                                keywords: ['resto', 'restaurant'],
                                icon: Icons.restaurant,
                                color: const Color(0xFFFB8C00),
                              );
                            },
                          ),
                          _OptionTile(
                            icon: Icons.local_cafe,
                            label: 'Cafés',
                            color: const Color(0xFF6D4C41),
                            onTap: () {
                              Navigator.pop(context);
                              _goToCategory(
                                title: "Cafés",
                                keywords: ['café', 'cafe', 'coffee'],
                                icon: Icons.local_cafe,
                                color: const Color(0xFF6D4C41),
                              );
                            },
                          ),
                          _OptionTile(
                            icon: Icons.local_taxi,
                            label: 'Transport',
                            color: const Color(0xFF00897B),
                            onTap: () {
                              Navigator.pop(context);
                              _goToCategory(
                                title: "Transport",
                                keywords: ['transport', 'gare', 'taxi'],
                                icon: Icons.local_taxi,
                                color: const Color(0xFF00897B),
                              );
                            },
                          ),
                          _OptionTile(
                            icon: Icons.shopping_bag,
                            label: 'Shopping',
                            color: const Color(0xFF8E24AA),
                            onTap: () {
                              Navigator.pop(context);
                              _goToCategory(
                                title: "Shopping",
                                keywords: ['shop', 'march', 'boutiq'],
                                icon: Icons.shopping_bag,
                                color: const Color(0xFF8E24AA),
                              );
                            },
                          ),
                          _OptionTile(
                            icon: Icons.local_hospital,
                            label: 'Santé',
                            color: Colors.red,
                            onTap: () {
                              Navigator.pop(context);
                              _goToCategory(
                                title: "Santé",
                                keywords: [
                                  'hôp',
                                  'hop',
                                  'sant',
                                  'cliniq',
                                  'pharma'
                                ],
                                icon: Icons.local_hospital,
                                color: Colors.red,
                              );
                            },
                          ),
                          _OptionTile(
                            icon: Icons.school,
                            label: 'Écoles',
                            color: const Color(0xFF3949AB),
                            onTap: () {
                              Navigator.pop(context);
                              _goToCategory(
                                title: "Écoles",
                                keywords: ['écol', 'ecol', 'univers'],
                                icon: Icons.school,
                                color: const Color(0xFF3949AB),
                              );
                            },
                          ),
                          _OptionTile(
                            icon: Icons.church,
                            label: 'Églises',
                            color: const Color(0xFF8E24AA),
                            onTap: () {
                              Navigator.pop(context);
                              _goToCategory(
                                title: "Églises",
                                keywords: ['églis', 'eglis', 'church'],
                                icon: Icons.church,
                                color: const Color(0xFF8E24AA),
                              );
                            },
                          ),
                          _OptionTile(
                            icon: Icons.park,
                            label: 'Parcs',
                            color: const Color(0xFF43A047),
                            onTap: () {
                              Navigator.pop(context);
                              _goToCategory(
                                title: "Parcs",
                                keywords: ['parc', 'natur'],
                                icon: Icons.park,
                                color: const Color(0xFF43A047),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Text("Utilitaires",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        children: [
                          _OptionTile(
                            icon: Icons.map,
                            label: 'Carte',
                            color: const Color(0xFF1E88E5),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onSwitchTab(1);
                            },
                          ),
                          _OptionTile(
                            icon: Icons.qr_code_scanner,
                            label: 'Scanner',
                            color: const Color(0xFF3949AB),
                            onTap: () {
                              Navigator.pop(context);
                              _push(const ScannerScreen());
                            },
                          ),
                          _OptionTile(
                            icon: Icons.payment,
                            label: 'Payer',
                            color: const Color(0xFF00897B),
                            onTap: () {
                              Navigator.pop(context);
                              _push(const PayScreen());
                            },
                          ),
                          _OptionTile(
                            icon: Icons.swap_horiz,
                            label: 'Échange',
                            color: const Color(0xFF00897B),
                            onTap: () {
                              Navigator.pop(context);
                              _push(const ExchangeScreen());
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Text("Compte",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        children: [
                          _OptionTile(
                            icon: Icons.person_outline,
                            label: 'Profil',
                            color: Colors.grey,
                            onTap: () {
                              Navigator.pop(context);
                              widget.onSwitchTab(3);
                            },
                          ),
                          _OptionTile(
                            icon: Icons.help_outline,
                            label: 'Aide',
                            color: const Color(0xFF1E88E5),
                            onTap: () {
                              Navigator.pop(context);
                              AppToast.info(context, "Aide bientôt");
                            },
                          ),
                          _OptionTile(
                            icon: Icons.info_outline,
                            label: 'À propos',
                            color: const Color(0xFF00897B),
                            onTap: () {
                              Navigator.pop(context);
                              AppToast.info(context, "À propos bientôt");
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadPopularPlaces,
        color: const Color(0xFF1E88E5),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderSection(onOpenNotifications: _openNotificationsSheet),
              const SizedBox(height: 25),

              // 👉 RECHERCHE + TRIER
              Row(
                children: [
                  // 8/10 — Barre de recherche
                  Expanded(
                    flex: 8,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              color: Colors.grey, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v.trim()),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: "Rechercher...",
                                hintStyle: TextStyle(
                                    color: Colors.grey, fontSize: 14),
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(Icons.close,
                                  color: Colors.grey, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 2/10 — Bouton Trier
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _openSortSheet,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.tune,
                                color: Color(0xFF1E88E5), size: 20),
                            SizedBox(height: 2),
                            Text("Trier",
                                style: TextStyle(
                                    color: Color(0xFF1E88E5),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 👉 Indicateur de tri actif
              if (_sortBy != 'nom')
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.sort,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("Trié par : $_sortLabel",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),

              const SizedBox(height: 25),

              // GRILLE
              _MenuGrid(onTap: _openMenuGrid),
              const SizedBox(height: 25),

              // LIEUX POPULAIRES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _searchQuery.isNotEmpty
                        ? "Résultats (${_displayedPlaces.length})"
                        : "Lieux populaires",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // 👉 SEUL "Voir tout" mène à AllPlacesScreen
                  if (_searchQuery.isEmpty)
                    GestureDetector(
                      onTap: _goToAllPlaces,
                      child: const Text("Voir tout",
                          style: TextStyle(
                              color: Color(0xFF1E88E5), fontSize: 14)),
                    ),
                ],
              ),
              const SizedBox(height: 15),
              _buildPlacesList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacesList() {
    if (_isLoadingPlaces) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
        ),
      );
    }

    if (_placesError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(_placesError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadPopularPlaces,
              child: const Text("Réessayer"),
            ),
          ],
        ),
      );
    }

    final places = _searchQuery.isEmpty
        ? _displayedPlaces.take(5).toList()
        : _displayedPlaces;

    if (places.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              _searchQuery.isNotEmpty
                  ? "Aucun résultat pour \"$_searchQuery\""
                  : "Aucun lieu disponible",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: places.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PlaceCard(place: p, onTap: () => _goToPlaceDetail(p)),
        );
      }).toList(),
    );
  }
}

// ==========================================
// HEADER
// ==========================================
class _HeaderSection extends StatelessWidget {
  final VoidCallback onOpenNotifications;
  const _HeaderSection({required this.onOpenNotifications});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final displayName = user != null
        ? (user.firstName.isNotEmpty ? user.firstName : user.username)
        : 'cher visiteur';
    final photo = user?.displayPhoto;

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFE3F2FD),
          backgroundImage: photo != null ? NetworkImage(photo) : null,
          child: photo == null
              ? const Icon(Icons.person,
                  color: Color(0xFF1E88E5), size: 32)
              : null,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Bonjour, $displayName 👋",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Bienvenue au Burundi !",
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
        GestureDetector(
          onTap: onOpenNotifications,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: const Icon(Icons.notifications_none, size: 28),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// GRILLE
// ==========================================
class _MenuGrid extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _MenuGrid({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final menus = [
      {'icon': Icons.map, 'label': 'Carte', 'color': const Color(0xFF1E88E5)},
      {
        'icon': Icons.chat_bubble,
        'label': 'Messagerie',
        'color': const Color(0xFF1E88E5)
      },
      {
        'icon': Icons.translate,
        'label': 'Traduction',
        'color': const Color(0xFF00897B)
      },
      {
        'icon': Icons.menu_book,
        'label': 'Apprendre',
        'color': const Color(0xFF8E24AA)
      },
      {
        'icon': Icons.currency_exchange,
        'label': 'Échange',
        'color': const Color(0xFF00897B)
      },
      {
        'icon': Icons.qr_code_scanner,
        'label': 'Scanner',
        'color': const Color(0xFF3949AB)
      },
      {
        'icon': Icons.payment,
        'label': 'Payer',
        'color': const Color(0xFF00897B)
      },
      {'icon': Icons.more_horiz, 'label': 'Plus', 'color': Colors.grey},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 15,
        childAspectRatio: 0.8,
      ),
      itemCount: menus.length,
      itemBuilder: (context, i) {
        final label = menus[i]['label'] as String;
        return GestureDetector(
          onTap: () => onTap(label),
          child: Column(
            children: [
              Container(
                height: 55,
                width: 55,
                decoration: BoxDecoration(
                  color: menus[i]['color'] as Color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(menus[i]['icon'] as IconData,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// CARTE LIEU
// ==========================================
class _PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  const _PlaceCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImg = place.imgUrl != null && place.imgUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasImg
                  ? Image.network(place.imgUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.nom,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(place.categorieNom,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF1E88E5)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
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

// ==========================================
// OPTION TILE
// ==========================================
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              height: 55,
              width: 55,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}