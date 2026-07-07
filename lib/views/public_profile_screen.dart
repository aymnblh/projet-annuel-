import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../utils/app_translations.dart';
import 'package:url_launcher/url_launcher.dart'; // AJOUT
import '../main.dart';
import 'product_card.dart';
import 'auth_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const PublicProfileScreen({super.key, required this.userId, required this.userName});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  String t(String key) => AppTranslations.get(languageNotifier.value, key);

  // --- LAISSER UN AVIS ---
  void _showRatingDialog() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(fromProfile: true)));
      return;
    }

    if (currentUserId == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vous ne pouvez pas vous noter vous-même !")));
      return;
    }

    final commentController = TextEditingController();
    double rating = 5.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isAr = languageNotifier.value == 'ar';
            return AlertDialog(
              title: Text(isAr ? "قيم هذا البائع" : "Noter ce vendeur"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 30,
                        ),
                        onPressed: () => setState(() => rating = index + 1.0),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: isAr ? "تعليق (اختياري)" : "Commentaire (Optionnel)",
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? "إلغاء" : "Annuler")),
                ElevatedButton(
                  onPressed: () async {
                    if (rating > 0) {
                      await FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('reviews').add({
                        'reviewerId': currentUserId,
                        'rating': rating,
                        'comment': commentController.text.trim(),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? "تم إرسال التقييم" : "Avis envoyé !")));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                  child: Text(isAr ? "إرسال" : "Envoyer"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = languageNotifier.value == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.userName,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.iconTheme.color),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.userId).get(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
          
          final userData = userSnap.data!.data() as Map<String, dynamic>?;
          final isPro = userData?['isPro'] == true;
          final isVerified = userData?['isVerified'] == true;
          final coverImage = userData?['coverImageUrl'] as String?;
          final whatsapp = userData?['whatsapp'] as String?;

          return SingleChildScrollView(
            child: Column(
              children: [
                // --- EN-TÊTE PROFIL (PRO: COVER IMAGE) ---
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // ARRIÈRE PLAN (Cover Image)
                    Container(
                      height: isPro ? 200 : 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isPro ? Colors.grey[800] : const Color(0xFF0F172A),
                        image: (isPro && coverImage != null) 
                          ? DecorationImage(image: NetworkImage(coverImage), fit: BoxFit.cover)
                          : null,
                      ),
                    ),
                    // AVATAR
                    Positioned(
                      bottom: -40,
                      child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: const Color(0xFF0F172A),
                        child: Text(
                        widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : "U",
                        style: const TextStyle(color: Colors.white, fontSize: 36),
                        ),
                      ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 50),
                
                // NOM + BADGE
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.userName, style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold)),
                    if (isVerified) ...[const SizedBox(width: 5), const Icon(Icons.verified, color: Colors.blue, size: 24)],
                    if (isPro) ...[const SizedBox(width: 5), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)), child: const Text("SHOWROOM", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)))],
                  ],
                ),

                // WHATSAPP BUTTON (PRO)
                if (isPro && whatsapp != null && whatsapp.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse("https://wa.me/$whatsapp")),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: const StadiumBorder()),
                      icon: const Icon(Icons.chat),
                      label: const Text("WhatsApp"),
                    ),
                  ),
                
                const SizedBox(height: 10),
                
                // NOTATION
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('reviews').snapshots(),
                  builder: (context, snapshot) {
                     if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Text(isAr ? "بائع جديد" : "Nouveau vendeur", style: GoogleFonts.cairo(color: Colors.grey));
                      }
                      
                      double total = 0;
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        total += (data['rating'] as num?)?.toDouble() ?? 0.0;
                      }
                       double avg = total / snapshot.data!.docs.length;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 5),
                          Text(
                            "${avg.toStringAsFixed(1)} / 5 (${snapshot.data!.docs.length} ${isAr ? 'آراء' : 'avis'})",
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                  }),

                  const SizedBox(height: 15),
                   ElevatedButton.icon(
                    onPressed: _showRatingDialog,
                    icon: const Icon(Icons.star_rate_rounded),
                    label: Text(isAr ? "قيم البائع" : "Noter ce vendeur"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[100],
                      foregroundColor: Colors.brown,
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 20),

                // --- ONGLET "SES ANNONCES" ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: theme.cardColor,
                  child: Text(
                    isPro ? (isAr ? "إعلانات المعرض" : "Vitrine du Showroom") : (isAr ? "إعلانات البائع" : "Annonces du vendeur"),
                    style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .where('sellerId', isEqualTo: widget.userId)
                      .where('isSold', isEqualTo: false)
                      .where('isApproved', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    final products = snapshot.data!.docs.map((d) => Product.fromFirestore(d)).toList();
                    final featuredProducts = products.where((p) => p.isBoosted).toList();
                    final standardProducts = products.where((p) => !p.isBoosted).toList();

                    if (products.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Text(isAr ? "لا توجد إعلانات أخرى" : "Aucune autre annonce", style: GoogleFonts.cairo(color: Colors.grey)),
                      );
                    }

                    return Column(
                      children: [
                        // --- SECTION "À LA UNE" (PRO ONLY) ---
                        if (isPro && featuredProducts.isNotEmpty) ...[
                           Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            alignment: Alignment.centerLeft,
                            child: Row(children: [
                              const Icon(Icons.flash_on, color: Colors.amber),
                              const SizedBox(width: 8),
                              Text("Véhicules en Vedette", style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber[800])),
                            ]),
                           ),
                           SizedBox(
                             height: 200,
                             child: ListView.builder(
                               padding: const EdgeInsets.symmetric(horizontal: 16),
                               scrollDirection: Axis.horizontal,
                               itemCount: featuredProducts.length,
                               itemBuilder: (ctx, i) => SizedBox(
                                 width: 160, 
                                 child: Padding(
                                   padding: const EdgeInsets.only(right: 10),
                                   child: ProductCard(product: featuredProducts[i]), 
                                 ),
                               ),
                             ),
                           ),
                           const Divider(height: 30),
                        ],

                        // --- ANNONCES STANDARD ---
                        GridView.builder(
                          shrinkWrap: true, 
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, 
                            childAspectRatio: 0.75, 
                            mainAxisSpacing: 16, 
                            crossAxisSpacing: 16
                          ),
                          itemCount: standardProducts.length,
                          itemBuilder: (context, index) => ProductCard(product: standardProducts[index]),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}