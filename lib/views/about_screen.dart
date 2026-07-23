import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("À propos"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Logo
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.directions_car, size: 60, color: Colors.amber),
            ),
          ),
          const SizedBox(height: 20),
          
          // App Name
          Center(
            child: Text(
              "OneClick Cars",
              style: GoogleFonts.cairo(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              "Plateforme de vente et achat de voitures en Europe",
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              "Version 1.0.0+13",
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 40),

          // Description
          _buildSection(
            "Qui sommes-nous ?",
            "OneClick Cars est une plateforme leader pour la vente et l'achat de voitures. Nous offrons une expérience fluide et sécurisée pour trouver la voiture de vos rêves ou vendre votre véhicule facilement.",
            isDark,
          ),
          const SizedBox(height: 20),

          // Features
          _buildSection(
            "Fonctionnalités",
            "",
            isDark,
          ),
          _buildFeature(Icons.search, "Recherche avancée avec filtres intelligents", isDark),
          _buildFeature(Icons.compare_arrows, "Comparaison de voitures", isDark),
          _buildFeature(Icons.notifications_active, "Alertes de recherche", isDark),
          _buildFeature(Icons.price_change, "Estimation de prix (Argus)", isDark),
          _buildFeature(Icons.dashboard, "Dashboard professionnel", isDark),
          const SizedBox(height: 30),

          // Copyright
          Center(
            child: Text(
              "© 2026 OneClick Cars. ${'Tous droits réservés'}.",
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.cairo(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700], height: 1.6),
          ),
        ],
      ],
    );
  }

  Widget _buildFeature(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
