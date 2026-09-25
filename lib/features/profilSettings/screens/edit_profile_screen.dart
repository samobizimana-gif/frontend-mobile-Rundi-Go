import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rundi_go/features/authentification/services/auth_service.dart';

import '../../../core/app_toast.dart';
import '../../../core/config.dart';
import '../../../core/api_client.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  String _langueCode = 'fr';
  String _countryCode = 'bi';
  String _originalLangueCode = 'fr'; // 👈 pour détecter le changement
  File? _photoFile;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _bioController.text = user.bio;
      _langueCode = user.languagePreferee;
      _originalLangueCode = user.languagePreferee;
      _countryCode = user.country;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ==========================================
  // PHOTO
  // ==========================================
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked == null) return;
      setState(() => _photoFile = File(picked.path));
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
                const Text("Changer la photo",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined,
                      color: Color(0xFF1E88E5)),
                  title: const Text("Galerie"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined,
                      color: Color(0xFF1E88E5)),
                  title: const Text("Caméra"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.camera);
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

  // ==========================================
  // SÉLECTION LANGUE / PAYS
  // ==========================================
  void _pickOption({
    required String title,
    required List<Map<String, String>> options,
    required String currentCode,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
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
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final opt = options[i];
                    final selected = currentCode == opt['code'];
                    return ListTile(
                      title: Text(opt['label']!,
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected
                                ? const Color(0xFF1E88E5)
                                : Colors.black87,
                          )),
                      trailing: selected
                          ? const Icon(Icons.check, color: Color(0xFF1E88E5))
                          : null,
                      onTap: () {
                        onSelected(opt['code']!);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _labelOf(List<Map<String, String>> list, String code) {
    return list.firstWhere((e) => e['code'] == code,
        orElse: () => {'label': code})['label']!;
  }

  // ==========================================
  // SAUVEGARDER
  // ==========================================
  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      // 👉 1. Si la langue a changé → appelle l'endpoint dédié
      if (_langueCode != _originalLangueCode) {
        await AuthService.instance.updateLanguage(_langueCode);
        print("🐛 Langue mise à jour : $_langueCode");
      }

      // 👉 2. Mise à jour des autres infos
      await AuthService.instance.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        country: _countryCode,
        languePreferee: _langueCode,
        photo: _photoFile,
      );

      if (!mounted) return;
      AppToast.success(context, "Profil mis à jour ✅");
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

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text("Modifier le profil",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PHOTO
              Center(
                child: GestureDetector(
                  onTap: _openPhotoSheet,
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF1E88E5), width: 2),
                        ),
                        child: ClipOval(
                          child: _photoFile != null
                              ? Image.file(_photoFile!, fit: BoxFit.cover)
                              : (user?.displayPhoto != null
                                  ? Image.network(user!.displayPhoto!,
                                      fit: BoxFit.cover)
                                  : Icon(Icons.person,
                                      size: 50, color: Colors.grey.shade400)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E88E5),
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

              // PRÉNOM
              _label("Prénom"),
              const SizedBox(height: 8),
              _field(
                  controller: _firstNameController,
                  icon: Icons.badge_outlined,
                  hint: "Votre prénom"),
              const SizedBox(height: 15),

              // NOM
              _label("Nom"),
              const SizedBox(height: 8),
              _field(
                  controller: _lastNameController,
                  icon: Icons.badge_outlined,
                  hint: "Votre nom"),
              const SizedBox(height: 15),

              // EMAIL
              _label("Email"),
              const SizedBox(height: 8),
              _field(
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  hint: "Email",
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 15),

              // TÉLÉPHONE
              _label("Téléphone"),
              const SizedBox(height: 8),
              _field(
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  hint: "+257 XX XX XX XX",
                  keyboard: TextInputType.phone),
              const SizedBox(height: 15),

              // BIO
              _label("Bio"),
              const SizedBox(height: 8),
              _field(
                  controller: _bioController,
                  icon: Icons.notes_outlined,
                  hint: "Parlez de vous"),
              const SizedBox(height: 15),

              // LANGUE
              _label("Langue préférée"),
              const SizedBox(height: 8),
              _dropdownField(
                icon: Icons.language,
                value: _labelOf(AppConfig.supportedLanguages, _langueCode),
                onTap: () => _pickOption(
                  title: "Choisir une langue",
                  options: AppConfig.supportedLanguages,
                  currentCode: _langueCode,
                  onSelected: (v) => setState(() => _langueCode = v),
                ),
              ),
              const SizedBox(height: 15),

              // PAYS
              _label("Pays"),
              const SizedBox(height: 8),
              _dropdownField(
                icon: Icons.flag_outlined,
                value: _labelOf(AppConfig.supportedCountries, _countryCode),
                onTap: () => _pickOption(
                  title: "Choisir un pays",
                  options: AppConfig.supportedCountries,
                  currentCode: _countryCode,
                  onSelected: (v) => setState(() => _countryCode = v),
                ),
              ),
              const SizedBox(height: 30),

              // BOUTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
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
                      : const Text("Enregistrer",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
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

  Widget _dropdownField({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.keyboard_arrow_down,
                color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }
}