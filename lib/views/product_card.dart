import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'product_details_screen.dart';
import 'auth_screen.dart'; // âœ… Import obligatoire
import '../utils/app_translations.dart';
import '../main.dart';
import '../widgets/optimized_image.dart';
import '../utils/app_constants.dart'; // Design system

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isSelected; // AJOUT POUR COMPARATEUR
  final VoidCallback? onLongPress; // AJOUT POUR COMPARATEUR

  const ProductCard({
    super.key, 
    required this.product,
    this.isSelected = false, 
    this.onLongPress,
  });

  String t(String key) => AppTranslations.get(languageNotifier.value, key);

  void _toggleFavorite(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    
    // 1. SI PAS CONNECTÃ‰ -> On envoie vers l'Ã©cran de connexion
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('login_required'))));
      
      // âœ… CORRECTION : On active fromProfile: true pour revenir ici aprÃ¨s la connexion
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen(fromProfile: true)));
      return;
    }

    // 2. SI CONNECTÃ‰ -> On ajoute/enlÃ¨ve des favoris
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').doc(product.id);
    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete(); // Enlever
    } else {
      await ref.set({'addedAt': FieldValue.serverTimestamp()}); // Ajouter
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
           // Si mode sÃ©lection actif (indiquÃ© par isSelected=true ou onLongPress non null et selectionnÃ©e), on gÃ¨re le tap comme une sÃ©lÃ©ction aussi ?
           // Pour l'instant on garde le comportement par dÃ©faut (dÃ©tails) sauf si on implÃ©mente une logique spÃ©cifique dans le parent.
           // Mais ici on va dire: si onLongPress est fourni, c'est que le parent gÃ¨re la sÃ©lection.
           if (onLongPress != null && isSelected) {
             onLongPress!(); // Toggle selection via tap si dÃ©jÃ  en mode sÃ©lection
           } else {
             Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)));
           }
        },
        onLongPress: onLongPress, // DÃ©clenche le mode sÃ©lection
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: isSelected ? Border.all(color: Colors.blue, width: 3) : Border.all(color: theme.dividerColor.withOpacity(0.1)),
            boxShadow: isSelected ? AppShadows.cardHover : AppShadows.card,
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE + ICONE FAVORIS
            Expanded(
              flex: 6, // Image prend plus de place (60-70%)
              child: Stack(
                children: [
                  Hero(
                    tag: product.id,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: OptimizedImage(
                        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls[0] : '',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Icone Favoris Flottante (Style Image 2)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: user != null 
                        ? FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').doc(product.id).snapshots()
                        : null,
                      builder: (context, snapshot) {
                        bool isFav = snapshot.hasData && snapshot.data!.exists;
                        return GestureDetector(
                          onTap: () => _toggleFavorite(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black54 : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : (isDark ? Colors.white : Colors.black),
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Badge Urgent/Boosted discret si besoin
                  if (product.isBoosted || product.isUrgent)
                    Positioned(
                      top: 10, left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.isUrgent ? Colors.red : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          product.isUrgent ? 'URGENT' : 'TOP',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  
                ],
              ),
            ),
            
                  // INFOS (Titre + Prix style minimaliste)
                  Expanded(
                    flex: 3, // ~30% pour le texte
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Titre
                          Text(
                            product.title, 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, 
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold, 
                              fontSize: 15,
                              color: theme.textTheme.bodyLarge?.color
                            )
                          ),
                          
                            // NOUVEAU : DÃ©tails Voiture (AnnÃ©e â€¢ Carburant)
                            if (product.year != null || product.fuel != null)
                              Text(
                                "${product.year ?? ''} â€¢ ${product.fuel ?? ''}", 
                                style: GoogleFonts.cairo(
                                  fontSize: 12, 
                                  color: isDark ? Colors.grey[400] : Colors.grey[600], 
                                  fontWeight: FontWeight.w500
                                )
                              ),

                            // RATING VENDEUR
                             StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('users').doc(product.sellerId).snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
                                final data = snapshot.data!.data() as Map<String, dynamic>;
                                final rating = (data['rating'] as num?)?.toDouble();
                                if (rating == null || rating == 0) return const SizedBox.shrink();

                                return Row(
                                  children: [
                                    Icon(Icons.star, size: 12, color: Colors.amber[700]),
                                    const SizedBox(width: 2),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                                    )
                                  ],
                                );
                              }
                            ),

                            // Prix & Localisation
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${product.price.toStringAsFixed(0)} EUR", 
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w800, 
                                    color: theme.colorScheme.primary, 
                                    fontSize: 16
                                  )
                                ),
                              ],
                            ),
                          
                          // Petite ligne grise pour la wilaya
                          Text(
                            "${product.commune ?? ''}, ${product.wilaya}", 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, 
                            style: GoogleFonts.cairo(
                              fontSize: 11, 
                              color: isDark ? Colors.grey[400] : Colors.grey[600]
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );
  }
}

