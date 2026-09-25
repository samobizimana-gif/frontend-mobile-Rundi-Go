import 'package:flutter/material.dart';
import 'package:rundi_go/core/api_client.dart';
import 'package:rundi_go/features/authentification/services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showSnack("Veuillez remplir tous les champs");
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.instance.login(
        username: username,
        password: password,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnack(e.message);
    } on NetworkException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack("Erreur inattendue : $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToRegister() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
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
        title: const Text("Connexion",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3F2FD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      size: 60, color: Color(0xFF1E88E5)),
                ),
              ),
              const SizedBox(height: 25),
              const Center(
                child: Text("Content de vous revoir !",
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text("Connectez-vous pour continuer",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 40),

              _label("Nom d'utilisateur"),
              const SizedBox(height: 8),
              _field(
                controller: _usernameController,
                icon: Icons.person_outline,
                hint: "ex: alice",
              ),
              const SizedBox(height: 20),

              _label("Mot de passe"),
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
              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
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
                      : const Text("Se connecter",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Pas de compte ? ",
                      style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: _goToRegister,
                    child: const Text(
                      "S'inscrire",
                      style: TextStyle(
                          color: Color(0xFF1E88E5),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
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
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: TextField(
        controller: controller,
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
}