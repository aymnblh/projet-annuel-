import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product.dart';
import '../product_card.dart';
// Pour Chat (à adapter si besoin)
// Meilleur target
// Si besoin
import '../../main.dart'; // Pour languageNotifier

class BoutiqueScreen extends StatelessWidget {
  final Map<String, dynamic> sellerData; // Données du user (isPro, storeName...)
  final String sellerId;

  const BoutiqueScreen({super.key, required this.sellerData, required this.sellerId});

  // Ouvrir Google Maps
  Future<void> _openMap() async {
    final GeoPoint? loc = sellerData['storeLocation'];
    if (loc != null) {
      final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}");
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isAr = languageNotifier.value == 'ar';
    String storeName = sellerData['storeName'] ?? "Boutique";
    String storeDesc = sellerData['storeDescription'] ?? "";
    String logoUrl = sellerData['logoUrl'] ?? "";
    String address = sellerData['storeAddress'] ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(storeName, style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // HEADER BOUTIQUE
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
                        child: logoUrl.isEmpty ? const Icon(Icons.store, size: 40, color: Colors.grey) : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(storeName, style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold)),
                            if (address.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Row(children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(address, style: const TextStyle(color: Colors.grey))),
                                ]),
                              ),
                             if (sellerData['storeLocation'] != null)
                               Padding(
                                 padding: const EdgeInsets.only(top: 8),
                                 child: InkWell(
                                   onTap: _openMap,
                                   child: Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                     decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(5)),
                                     child: Text(isAr ? "📍 التوجه للمحل" : "📍 Y aller (Maps)", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                                   ),
                                 ),
                               )
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (storeDesc.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Text(storeDesc, style: GoogleFonts.cairo(color: Colors.black87), textAlign: TextAlign.center),
                    ),
                    
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                         // Ouvrir Chat
                         // Pour contacter la boutique, on doit idéalement avoir un productId. 
                         // Si c'est un chat "général", la logique actuelle de ChatService demande un productId.
                         // Simplification : On ne redirige pas directement vers ChatRoomScreen ici sans productId valide
                         // dans l'architecture actuelle. 
                         // Alternative : Message "Veuillez contacter via un produit spécifique".
                         
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez sélectionner un produit pour contacter le vendeur.")));
                         
                         /* 
                         Navigator.push(context, MaterialPageRoute(builder: (_) => ChatRoomScreen(
                           chatId: "temp", 
                           otherUserName: storeName,
                           productName: "Boutique", // Placeholder
                         )));
                         */
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(isAr ? "مراسلة المتجر" : "Contacter la boutique"),
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // TITRE GRID
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(isAr ? "المنتجات" : "Produits en vente", style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),

          // GRILLE PRODUITS
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products')
                .where('sellerId', isEqualTo: sellerId)
                .where('isSold', isEqualTo: false)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              if (snapshot.data!.docs.isEmpty) return SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(isAr ? "لا توجد منتجات حاليا" : "Aucun produit pour le moment"))));

              final products = snapshot.data!.docs.map((d) => Product.fromFirestore(d)).toList();

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(product: products[index]),
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
