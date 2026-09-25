import 'package:flutter/material.dart';
import 'package:rundi_go/features/authentification/services/auth_service.dart';
import 'package:rundi_go/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👉 Restaure la session si token existe
  await AuthService.instance.bootstrap();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RundiGo',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const WelcomeScreen(), // 👈 Ton écran d'accueil
    );
  }
}