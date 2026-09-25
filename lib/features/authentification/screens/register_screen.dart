import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rundi_go/core/api_client.dart';
import 'package:rundi_go/core/app_toast.dart';
import 'package:rundi_go/core/config.dart';
import 'package:rundi_go/features/authentification/services/auth_service.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _langueCode = 'fr';
  String _countryCode = 'bi';
  bool _wantsGerant = false;
  bool _loading = false;
  bool _obscure = true;

  File? _photoFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
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
                const Text("Photo de profil",
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
                  title: const Text("Prendre une photo"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                if (_photoFile != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: Colors.red),
                    title: const Text("Retirer la photo",
                        style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _photoFile = null);
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
  // REGISTER
  // ==========================================
  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      AppToast.error(context, "Nom, email et mot de passe requis");
      return;
    }
    if (!email.contains('@')) {
      AppToast.error(context, "Email invalide");
      return;
    }
    if (password.length < 8) {
      AppToast.error(context, "Le mot de passe doit contenir au moins 8 caractères");
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.instance.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        languePreferee: _langueCode,
        country: _countryCode,
        wantsGerant: _wantsGerant,
        photo: _photoFile,
      );
      if (!mounted) return;
      AppToast.success(context, "Compte créé ✅");
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.pop(context, true);
      });
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

  void _goToLogin() => Navigator.pop(context);

  // ==========================================
  // SÉLECTION
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
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              ...options.map((opt) {
                final isSelected = currentCode == opt['code'];
                return ListTile(
                  title: Text(opt['label']!),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF1E88E5))
                      : null,
                  onTap: () {
                    onSelected(opt['code']!);
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

  String _labelOf(List<Map<String, String>> list, String code) {
    return list.firstWhere((e) => e['code'] == code,
        orElse: () => {'label': code})['label']!;
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
        title: const Text("Inscription",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Text("Créer un compte",
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text("Rejoignez RundiGo en quelques secondes",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 25),

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
                              : Icon(Icons.add_a_photo_outlined,
                                  size: 40, color: Colors.grey.shade400),
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
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _photoFile != null ? "Photo ajoutée ✓" : "Ajouter une photo",
                  style: TextStyle(
                    fontSize: 12,
                    color: _photoFile != null
                        ? const Color(0xFF4CAF50)
                        : Colors.grey,
                    fontWeight: _photoFile != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              _label("Nom d'utilisateur *"),
              const SizedBox(height: 8),
              _field(
                  controller: _usernameController,
                  icon: Icons.person_outline,
                  hint: "ex: alice"),
              const SizedBox(height: 15),

              _label("Email *"),
              const SizedBox(height: 8),
              _field(
                controller: _emailController,
                icon: Icons.email_outlined,
                hint: "exemple@rundigo.com",
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Prénom"),
                        const SizedBox(height: 8),
                        _field(
                            controller: _firstNameController,
                            icon: Icons.badge_outlined,
                            hint: "Alice"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label("Nom"),
                        const SizedBox(height: 8),
                        _field(
                            controller: _lastNameController,
                            icon: Icons.badge_outlined,
                            hint: "N."),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              _label("Langue préférée"),
              const SizedBox(height: 8),
              _dropdownField(
                icon: Icons.language,
                value: _labelOf(AppConfig.supportedLanguages, _langueCode),
                onTap: () => _pickOption(
                  title: "Choisir une langue",
                  options: AppConfig.supportedLanguages,
                  currentCode: _langueCode,
                  onSelected: (code) => setState(() => _langueCode = code),
                ),
              ),
              const SizedBox(height: 15),

              _label("Pays"),
              const SizedBox(height: 8),
              _dropdownField(
                icon: Icons.flag_outlined,
                value: _labelOf(AppConfig.supportedCountries, _countryCode),
                onTap: () => _pickOption(
                  title: "Choisir un pays",
                  options: AppConfig.supportedCountries,
                  currentCode: _countryCode,
                  onSelected: (code) => setState(() => _countryCode = code),
                ),
              ),
              const SizedBox(height: 15),

              _label("Mot de passe * (min 8 caractères)"),
              const SizedBox(height: 8),
              _field(
                controller: _passwordController,
                icon: Icons.lock_outline,
                hint: "••••••••",
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 15),

              // SWITCH GÉRANT
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 8),
                  ],
                ),
                child: SwitchListTile(
                  value: _wantsGerant,
                  onChanged: (v) => setState(() => _wantsGerant = v),
                  title: const Text("Devenir gérant",
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text(
                      "Hôtel, restaurant ou logement",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  activeColor: const Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
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
                      : const Text("Créer mon compte",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Déjà un compte ? ",
                      style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: _goToLogin,
                    child: const Text("Se connecter",
                        style: TextStyle(
                            color: Color(0xFF1E88E5),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
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
    bool obscure = false,
    Widget? suffix,
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
        obscureText: obscure,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: suffix,
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