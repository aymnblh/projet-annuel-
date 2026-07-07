import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isAr = languageNotifier.value == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? "حول التطبيق" : "À propos"),
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
              isAr ? "منصة بيع وشراء السيارات في الجزائر" : "Plateforme de vente et achat de voitures en Algérie",
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
            isAr ? "من نحن" : "Qui sommes-nous ?",
            isAr 
              ? "OneClick Cars هي منصة جزائرية رائدة لبيع وشراء السيارات. نوفر تجربة سلسة وآمنة للمستخدمين للعثور على سيارة أحلامهم أو بيع سياراتهم بسهولة."
              : "OneClick Cars est une plateforme algérienne leader pour la vente et l'achat de voitures. Nous offrons une expérience fluide et sécurisée pour trouver la voiture de vos rêves ou vendre votre véhicule facilement.",
            isDark,
          ),
          const SizedBox(height: 20),

          // Features
          _buildSection(
            isAr ? "المميزات" : "Fonctionnalités",
            "",
            isDark,
          ),
          _buildFeature(Icons.search, isAr ? "بحث متقدم مع فلاتر ذكية" : "Recherche avancée avec filtres intelligents", isDark),
          _buildFeature(Icons.compare_arrows, isAr ? "مقارنة السيارات" : "Comparaison de voitures", isDark),
          _buildFeature(Icons.notifications_active, isAr ? "تنبيهات البحث" : "Alertes de recherche", isDark),
          _buildFeature(Icons.price_change, isAr ? "تقدير الأسعار (Argus)" : "Estimation de prix (Argus)", isDark),
          _buildFeature(Icons.dashboard, isAr ? "لوحة تحكم للمحترفين" : "Dashboard professionnel", isDark),
          const SizedBox(height: 30),

          // Copyright
          Center(
            child: Text(
              "© 2026 OneClick Cars. ${isAr ? 'جميع الحقوق محفوظة' : 'Tous droits réservés'}.",
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
