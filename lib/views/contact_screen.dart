import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Contactez-nous"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Center(
            child: Icon(
              Icons.contact_support,
              size: 80,
              color: isDark ? Colors.blueAccent : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              "Nous sommes là pour vous aider",
              style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              "Contactez-nous via l'un des moyens suivants",
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),

          // Contact Methods
          _buildContactCard(
            icon: Icons.email,
            title: "Email",
            subtitle: "support@oneclickcars.dz",
            onTap: () => _launchUrl("mailto:support@oneclickcars.dz"),
            isDark: isDark,
          ),
          const SizedBox(height: 15),
          
          _buildContactCard(
            icon: Icons.phone,
            title: "Téléphone",
            subtitle: "+213 XXX XXX XXX",
            onTap: () => _launchUrl("tel:+213XXXXXXXXX"),
            isDark: isDark,
          ),
          const SizedBox(height: 15),
          
          _buildContactCard(
            icon: Icons.facebook,
            title: "Facebook",
            subtitle: "@oneclickcars",
            onTap: () => _launchUrl("https://facebook.com/oneclickcars"),
            isDark: isDark,
          ),
          const SizedBox(height: 15),
          
          _buildContactCard(
            icon: Icons.camera_alt,
            title: "Instagram",
            subtitle: "@oneclickcars",
            onTap: () => _launchUrl("https://instagram.com/oneclickcars"),
            isDark: isDark,
          ),
          const SizedBox(height: 40),

          // Business Hours
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Horaires d'ouverture",
                  style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildHourRow("Dimanche - Jeudi", "09:00 - 18:00", isDark),
                _buildHourRow("Vendredi", "Fermé", isDark),
                _buildHourRow("Samedi", "10:00 - 16:00", isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE0F2FE),
          child: Icon(icon, color: isDark ? Colors.blueAccent : const Color(0xFF0F172A)),
        ),
        title: Text(title, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: GoogleFonts.cairo(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildHourRow(String day, String hours, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: GoogleFonts.cairo(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.grey[700])),
          Text(hours, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        ],
      ),
    );
  }
}
