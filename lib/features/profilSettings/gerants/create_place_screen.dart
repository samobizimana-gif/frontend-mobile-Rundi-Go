import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rundi_go/features/map/models/place_category.dart';
import 'package:rundi_go/features/social/service_manager.dart';

import '../../../core/api_client.dart';
import '../../../core/app_toast.dart';
import '../../../core/config.dart';
import '../../../services/place_service.dart';

class CreatePlaceScreen extends StatefulWidget {
  const CreatePlaceScreen({super.key});

  @override
  State<CreatePlaceScreen> createState() => _CreatePlaceScreenState();
}

class _CreatePlaceScreenState extends State<CreatePlaceScreen> {
  final _nomController = TextEditingController();
  final _villeController = TextEditingController();
  final _adresseController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _prixController = TextEditingController();
  final _latController = TextEditingController(text: '-3.4264');
  final _lngController = TextEditingController(text: '29.9306');

  int? _selectedCategoryId;
  String _pays = 'bi';
  File? _imageFile;
  bool _loading = false;

  bool _isLoadingCategories = true;
  String? _categoriesError;
  List<PlaceCategory> _categories = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _villeController.dispose();
    _adresseController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _prixController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoriesError = null;
    });

    try {
      final cats = await PlaceService.instance.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        if (cats.isNotEmpty) _selectedCategoryId = cats.first.id;
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesError = "Impossible de charger les catégories";
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
      );
      if (picked == null) return;
      setState(() => _imageFile = File(picked.path));
    } catch (e) {
      AppToast.error(context, "Erreur photo : $e");
    }
  }

  void _openPhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SafeArea(
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
                const Text("Photo de l'établissement",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: Color(0xFF1E88E5)),
                  title: const Text("Galerie"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined,
                      color: Color(0xFF1E88E5)),
                  title: const Text("Caméra"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final nom = _nomController.text.trim();
    final ville = _villeController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (nom.isEmpty) {
      AppToast.error(context, "Le nom est requis");
      return;
    }
    if (_selectedCategoryId == null) {
      AppToast.error(context, "Choisissez une catégorie");
      return;
    }
    if (ville.isEmpty) {
      AppToast.error(context, "La ville est requise");
      return;
    }
    if (lat == null || lng == null) {
      AppToast.error(context, "Position invalide");
      return;
    }

    setState(() => _loading = true);

    try {
      final prix = double.tryParse(_prixController.text.trim());

      await ManagerService.instance.createPlace(
        nom: nom,
        categorieId: _selectedCategoryId!,
        ville: ville,
        latitude: lat,
        longitude: lng,
        pays: _pays,
        adresse: _adresseController.text.trim(),
        description: _descriptionController.text.trim(),
        website: _websiteController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        prixReference: prix,
        image: _imageFile, http: null,
      );

      if (!mounted) return;
      AppToast.success(context, "Établissement créé ✅");
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } on NetworkException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } catch (e) {
      if (mounted) AppToast.error(context, "Erreur : $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text("Nouvel établissement",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoadingCategories
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
              )
            : _categoriesError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off,
                              size: 60, color: Colors.grey),
                          const SizedBox(height: 15),
                          Text(_categoriesError!),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: _loadCategories,
                            child: const Text("Réessayer"),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _openPhotoSheet,
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                        color: const Color(0xFF4CAF50),
                                        width: 2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: _imageFile != null
                                        ? Image.file(_imageFile!,
                                            fit: BoxFit.cover)
                                        : const Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 50,
                                            color: Colors.grey),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        _label("Nom *"),
                        const SizedBox(height: 8),
                        _field(
                            controller: _nomController,
                            icon: Icons.store_outlined,
                            hint: "Ex: Hôtel Source du Nil"),
                        const SizedBox(height: 15),

                        _label("Catégorie *"),
                        const SizedBox(height: 8),
                        _categoryDropdown(),
                        const SizedBox(height: 15),

                        _label("Ville *"),
                        const SizedBox(height: 8),
                        _field(
                            controller: _villeController,
                            icon: Icons.location_city,
                            hint: "Ex: Gitega"),
                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label("Latitude *"),
                                  const SizedBox(height: 8),
                                  _field(
                                      controller: _latController,
                                      icon: Icons.pin_drop_outlined,
                                      hint: "-3.4264",
                                      keyboard: const TextInputType
                                          .numberWithOptions(
                                          signed: true, decimal: true)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label("Longitude *"),
                                  const SizedBox(height: 8),
                                  _field(
                                      controller: _lngController,
                                      icon: Icons.pin_drop_outlined,
                                      hint: "29.9306",
                                      keyboard: const TextInputType
                                          .numberWithOptions(
                                          signed: true, decimal: true)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        _label("Pays"),
                        const SizedBox(height: 8),
                        _paysDropdown(),
                        const SizedBox(height: 15),

                        _label("Adresse"),
                        const SizedBox(height: 8),
                        _field(
                            controller: _adresseController,
                            icon: Icons.home_outlined,
                            hint: "Rue, quartier..."),
                        const SizedBox(height: 15),

                        _label("Description"),
                        const SizedBox(height: 8),
                        _field(
                            controller: _descriptionController,
                            icon: Icons.notes_outlined,
                            hint: "Décrivez votre établissement",
                            maxLines: 3),
                        const SizedBox(height: 15),

                        _label("Téléphone (Lumicash)"),
                        const SizedBox(height: 8),
                        _field(
                            controller: _phoneController,
                            icon: Icons.phone_outlined,
                            hint: "+257 XX XX XX XX",
                            keyboard: TextInputType.phone),
                        const SizedBox(height: 15),

                        _label("Email"),
                        const SizedBox(height: 8),
                        _field(
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            hint: "contact@exemple.com",
                            keyboard: TextInputType.emailAddress),
                        const SizedBox(height: 15),

                        _label("Site web"),
                        const SizedBox(height: 8),
                        _field(
                            controller: _websiteController,
                            icon: Icons.language,
                            hint: "https://...",
                            keyboard: TextInputType.url),
                        const SizedBox(height: 15),

                        if (_isLogementCategory()) ...[
                          _label("Prix de référence (BIF / nuit)"),
                          const SizedBox(height: 8),
                          _field(
                              controller: _prixController,
                              icon: Icons.attach_money,
                              hint: "Ex: 50000",
                              keyboard: TextInputType.number),
                          const SizedBox(height: 8),
                          const Text(
                            "Ce prix sert de base à la commission (10%).",
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 15),
                        ],

                        const SizedBox(height: 15),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFB8C00)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Color(0xFFFB8C00), size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Votre établissement sera masqué jusqu'à vérification par un administrateur.",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text("Créer l'établissement",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }

  bool _isLogementCategory() {
    if (_selectedCategoryId == null) return false;
    final cat = _categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => PlaceCategory(id: 0, nom: ''),
    );
    final n = cat.nom.toLowerCase();
    return n.contains('logement') ||
        n.contains('héberg') ||
        n.contains('heberg') ||
        n.contains('hôtel') ||
        n.contains('hotel');
  }

  Widget _categoryDropdown() {
    if (_categories.isEmpty) {
      return const Text("Aucune catégorie disponible");
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedCategoryId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: _categories.map((c) {
            return DropdownMenuItem<int>(
              value: c.id,
              child: Text(c.nom, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
        ),
      ),
    );
  }

  Widget _paysDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _pays,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: AppConfig.supportedCountries.map((c) {
            return DropdownMenuItem<String>(
              value: c['code']!,
              child:
                  Text(c['label']!, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (v) => setState(() => _pays = v ?? 'bi'),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87));

  Widget _field({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        ),
      ),
    );
  }
}