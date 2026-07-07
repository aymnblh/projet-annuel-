import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../rental/rental_home_screen.dart';
import '../add_product_screen.dart';
import '../inbox_screen.dart';
import '../favorites_screen.dart';
import '../profile_screen.dart';
import '../../providers/app_mode_provider.dart';

class RentalMobileLayout extends StatefulWidget {
  const RentalMobileLayout({super.key});

  @override
  State<RentalMobileLayout> createState() => _RentalMobileLayoutState();
}

class _RentalMobileLayoutState extends State<RentalMobileLayout> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const RentalHomeScreen(),
      const InboxScreen(),
      // AddProductScreen with rental mode pre-selected
      const AddProductScreen(initialListingType: 'rent'),
      FavoritesScreen(onBrowseAds: () => _onItemTapped(0)),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex],
          // Mode toggle pill — always visible at bottom-right
          Positioned(
            bottom: 90,
            right: 16,
            child: _ModeSwitchFab(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 2,
        indicatorColor: const Color(0xFF7C3AED).withOpacity(0.12),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.vpn_key_outlined),
            selectedIcon: const Icon(Icons.vpn_key_rounded,
                color: Color(0xFF7C3AED)),
            label: 'Location',
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble,
                color: theme.colorScheme.primary),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            label: 'Louer',
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite,
                color: theme.colorScheme.primary),
            label: 'Favoris',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person,
                color: theme.colorScheme.primary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Floating pill to switch between Buy and Rent mode
class _ModeSwitchFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Provider.of<AppModeProvider>(context, listen: false)
          .setMode('sale'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_rounded,
                color: Color(0xFF4ECDC4), size: 16),
            const SizedBox(width: 6),
            Text(
              'Acheter',
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
