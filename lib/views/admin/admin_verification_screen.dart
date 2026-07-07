import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminVerificationScreen extends StatelessWidget {
  const AdminVerificationScreen({super.key});

  // --- ACTIONS ---
  Future<void> _approve(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'verificationStatus': 'verified',
        'isVerified': true, // Badge bleu
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Utilisateur vérifié ✅"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  Future<void> _reject(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'verificationStatus': 'rejected',
        'isVerified': false,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Demande rejetée ❌"), backgroundColor: Colors.orange));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Dashboard 👑", style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users')
            .where('verificationStatus', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text("Aucune demande en attente.", style: GoogleFonts.cairo()));
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final uid = docs[index].id;
              final name = data['name'] ?? 'Utilisateur';
              final idUrl = data['verificationIdUrl'] ?? '';
              final selfieUrl = data['verificationSelfieUrl'] ?? '';
              final date = data['verificationRequestedAt'] != null 
                  ? (data['verificationRequestedAt'] as Timestamp).toDate() 
                  : DateTime.now();

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Demandeur: $name", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("Reçu: ${timeago.format(date)}", style: GoogleFonts.cairo(color: Colors.grey)),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: _buildImagePreview(context, "ID Card", idUrl)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildImagePreview(context, "Selfie", selfieUrl)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _reject(context, uid),
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text("REFUSER", style: TextStyle(color: Colors.red)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approve(context, uid),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text("VALIDER", style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context, String label, String url) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
               appBar: AppBar(),
               body: Center(child: InteractiveViewer(child: CachedNetworkImage(imageUrl: url))),
             )));
          },
          child: Container(
            height: 150,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
            child: url.isEmpty 
              ? const Icon(Icons.broken_image) 
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, width: double.infinity),
                ),
          ),
        ),
      ],
    );
  }
}
