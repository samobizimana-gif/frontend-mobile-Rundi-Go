import 'package:flutter/material.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Taille de l'écran pour rendre le design réactif
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. IMAGE DE FOND
          Positioned.fill(
            child: Image.network(
              // Remplacez par votre image locale: Image.asset('assets/background.jpg')
              'https://images.unsplash.com/photo-1504214208698-ea1916a2195a?q=80&w=2070&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),

          // 2. FILTRE SOMBRE (Dégradé) pour la lisibilité du texte
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // 3. CONTENU PRINCIPAL
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),

                // --- LOGO ET TITRE ---
                // C'est ici que vous mettrez votre logo
                Container(
                  height: 100,
                  width: 100,
                  decoration: const BoxDecoration(
                    // Si vous avez un logo local, utilisez Image.asset
                    // Sinon, voici un placeholder qui ressemble à l'original
                    shape: BoxShape.circle,
                  ),
                  // REMPLACEZ CETTE ICONE PAR VOTRE IMAGE
                  child: ClipOval(
                    child: Image.network(
                      // Exemple d'icône de localisation (pin)
                      'https://cdn-icons-png.flaticon.com/512/684/684908.png',
                      fit: BoxFit.contain,
                      color: Colors
                          .white, // À retirer si votre logo a ses propres couleurs
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Titre "RundiGo" -> Remplacé par votre logo ou texte
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: 'Rundi'),
                      TextSpan(
                        text: 'Go',
                        style: TextStyle(color: Color(0xFF00D68F)), // Vert
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Sous-titre
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    "Un visiteur n'est plus\njamais dehors.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // --- ICÔNES DES FONCTIONNALITÉS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      FeatureItem(
                        icon: Icons.explore_outlined,
                        label: 'Explorer',
                      ),
                      FeatureItem(
                        icon: Icons.chat_bubble_outline,
                        label: 'Communiquer',
                      ),
                      FeatureItem(
                        icon: Icons.directions_car_outlined,
                        label: 'Se déplacer',
                      ),
                      FeatureItem(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Payer',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --- BOUTONS ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    children: [
                      // Bouton COMMENCER (Vert)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF00D68F,
                            ), // Vert vif
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Commencer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Bouton SE CONNECTER (Transparent avec bordure)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget réutilisable pour les icônes du menu
class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const FeatureItem({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2), // Fond semi-transparent
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
