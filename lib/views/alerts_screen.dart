import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/user_provider.dart';
import '../../utils/app_translations.dart';
import '../../main.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Connectez-vous pour voir vos alertes.")));

    return Scaffold(
      appBar: AppBar(title: Text("Mes Alertes")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('search_alerts').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Erreur: ${snapshot.error}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
                   const SizedBox(height: 20),
                   Text(
                     "Aucune alerte enregistrée",
                     style: const TextStyle(color: Colors.grey, fontSize: 16)
                   ),
                   const SizedBox(height: 10),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 40),
                     child: Text(
                       "Faites une recherche et sauvegardez-la pour être notifié des nouvelles voitures.",
                       textAlign: TextAlign.center,
                       style: const TextStyle(color: Colors.grey, fontSize: 12)
                     ),
                   )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final filters = data['filters'] as Map<String, dynamic>? ?? {};
              
              // Construire un sous-titre lisible des filtres
              List<String> details = [];
              if (filters.containsKey('brand') && filters['brand'] != null) details.add(filters['brand']);
              if (filters.containsKey('minYear') && filters['minYear'] != null) details.add("> ${filters['minYear']}");
              if (filters.containsKey('maxPrice') && filters['maxPrice'] != null) details.add("< ${filters['maxPrice']} EUR");
              if (filters.containsKey('fuel') && filters['fuel'] != null) details.add(filters['fuel']);

              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
                    child: Icon(Icons.notifications_active, color: isDark ? Colors.blueAccent : const Color(0xFF0F172A)),
                  ),
                  title: Text(data['label'] ?? "Recherche", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (details.isNotEmpty) Text(details.join(" • "), style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700])),
                      Text(timeago.format(data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now()), style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[500] : Colors.grey)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => Provider.of<UserProvider>(context, listen: false).deleteSearchAlert(doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

