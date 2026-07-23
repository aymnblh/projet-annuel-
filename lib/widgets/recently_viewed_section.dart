import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/recently_viewed_service.dart';
import '../models/product.dart';
import '../widgets/optimized_image.dart';
import '../views/product_details_screen.dart';
import '../utils/app_translations.dart';
import '../main.dart';
import '../utils/app_constants.dart'; // Design system

/// Horizontal scrollable section showing recently viewed products
class RecentlyViewedSection extends StatelessWidget {
  const RecentlyViewedSection({super.key});

  String t(String key) => AppTranslations.get(languageNotifier.value, key);

  Future<List<Product>> _fetchProducts(List<String> productIds) async {
    if (productIds.isEmpty) return [];
    
    final products = <Product>[];
    
    // Fetch in batches of 10 (Firestore limit)
    for (var i = 0; i < productIds.length; i += 10) {
      final batch = productIds.skip(i).take(10).toList();
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      
      products.addAll(snapshot.docs.map((doc) => Product.fromFirestore(doc)));
    }
    
    return products;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return StreamBuilder<List<String>>(
      stream: RecentlyViewedService.getRecentlyViewed(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSkeleton();
        }

        // Empty state
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Don't show section if empty
        }

        final productIds = snapshot.data!;

        return FutureBuilder<List<Product>>(
          future: _fetchProducts(productIds),
          builder: (context, productSnapshot) {
            if (!productSnapshot.hasData) {
              return _buildLoadingSkeleton();
            }

            final products = productSnapshot.data!;
            if (products.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: theme.iconTheme.color?.withOpacity(0.7),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t('recently_viewed'),
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => _showClearDialog(context),
                        child: Text(
                          t('recently_viewed_clear'),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Horizontal List
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return CompactProductCard(
                        product: products[index],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Container(
            height: 20,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 140,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showClearDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('recently_viewed_clear_confirm_title')),
        content: Text(t('recently_viewed_clear_confirm_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t('recently_viewed_clear')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await RecentlyViewedService.clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('recently_viewed_cleared')),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

/// Compact product card for horizontal lists
class CompactProductCard extends StatelessWidget {
  final Product product;

  const CompactProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: product.imageUrls.isNotEmpty
                    ? OptimizedImage(
                        imageUrl: product.imageUrls.first,
                        width: 140,
                        height: 120,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 40),
                      ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),

                    // Price
                    Text(
                      '${product.price.toStringAsFixed(0)} EUR',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
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

