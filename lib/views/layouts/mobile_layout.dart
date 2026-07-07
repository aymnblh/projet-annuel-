import 'package:flutter/material.dart';
import '../home_screen.dart'; // Import relatif si même dossier, sinon ajuster
import '../profile_screen.dart';
import '../inbox_screen.dart';
import '../add_product_screen.dart';
import '../favorites_screen.dart';
// Note: Adaptez les imports selon l'emplacement réel de vos fichiers

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  int _selectedIndex = 0;

  // Liste des écrans principaux
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),       // Index 0: Accueil
      const InboxScreen(),      // Index 1: Messages
      const AddProductScreen(), // Index 2: Vendre (Bouton central)
      FavoritesScreen(onBrowseAds: () => _onItemTapped(0)), // Index 3: Favoris
      const ProfileScreen(),    // Index 4: Profil
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Adaptative
        elevation: 2,
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Theme.of(context).colorScheme.primary),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary, // Couleur dynamique
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
            ),
            label: 'Vendre',
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary),
            label: 'Favoris',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
