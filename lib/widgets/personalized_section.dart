import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';

import '../main.dart'; // languageNotifier
import '../models/product.dart';
import '../services/recommendation_service.dart';
import '../services/behavior_tracking_service.dart';
import '../widgets/optimized_image.dart';
import '../views/product_details_screen.dart';

/// Displays two personalised horizontal carousels:
///   1. 🎯 Recommandé pour vous — products matching the user's interest profile
///   2. ✨ Découvertes          — products outside the user's usual patterns
///
/// The widget hides itself gracefully when the user is not logged in,
/// has insufficient browsing history, or when both lists are empty.
class PersonalizedSection extends StatefulWidget {
  const PersonalizedSection({super.key});

  @override
  State<PersonalizedSection> createState() => _PersonalizedSectionState();
}

class _PersonalizedSectionState extends State<PersonalizedSection> {
  List<Product>? _recommended;
  List<Product>? _discovery;
  bool _isLoading = true;
  bool _hasProfile = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Check if user has enough data for personalisation
      final profile = await BehaviorTrackingService().getInterestProfile();
      if (profile == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _hasProfile = true;

      // Fetch both lists in parallel
      final results = await Future.wait([
        RecommendationService.getPersonalizedRecommendations(user.uid,
            limit: 10),
        RecommendationService.getDiscoveryRecommendations(user.uid, limit: 5),
      ]);

      if (mounted) {
        setState(() {
          _recommended = results[0];
          _discovery = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[PersonalizedSection] Error loading recommendations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ────────────────────────────────────────────
  // Build
  // ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    final bool isAr = languageNotifier.value == 'ar';

    // Loading state — show shimmer skeletons
    if (_isLoading) {
      return _buildShimmerSection(context, isAr);
    }

    // Not enough browsing data
    if (!_hasProfile) return const SizedBox.shrink();

    // Both lists empty → hide
    final hasRecommended = _recommended != null && _recommended!.isNotEmpty;
    final hasDiscovery = _discovery != null && _discovery!.isNotEmpty;
    if (!hasRecommended && !hasDiscovery) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section 1: Recommended ──
        if (hasRecommended) ...[
          _buildSectionHeader(
            context,
            icon: '🎯',
            titleFr: 'Recommandé pour vous',
            titleAr: 'موصى لك',
            isAr: isAr,
          ),
          const SizedBox(height: 12),
          _buildHorizontalList(context, _recommended!),
          const SizedBox(height: 24),
        ],

        // ── Section 2: Discovery ──
        if (hasDiscovery) ...[
          _buildSectionHeader(
            context,
            icon: '✨',
            titleFr: 'Découvertes',
            titleAr: 'اكتشافات',
            isAr: isAr,
          ),
          const SizedBox(height: 12),
          _buildHorizontalList(context, _discovery!),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ────────────────────────────────────────────
  // Sub-widgets
  // ────────────────────────────────────────────

  Widget _buildSectionHeader(
    BuildContext context, {
    required String icon,
    required String titleFr,
    required String titleAr,
    required bool isAr,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isAr ? titleAr : titleFr,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(BuildContext context, List<Product> products) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _ProductCard(product: products[index]);
        },
      ),
    );
  }

  Widget _buildShimmerSection(BuildContext context, bool isAr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title shimmer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: 200,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Cards shimmer
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: 165,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ────────────────────────────────────────────
// Product Card (private)
// ────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        width: 165,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                    child: OptimizedImage(
                      imageUrl: product.imageUrls.isNotEmpty
                          ? product.imageUrls[0]
                          : '',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Brand badge
                  if (product.brand != null && product.brand!.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.brand!.toUpperCase(),
                          style: GoogleFonts.cairo(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info ──
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Price
                  Text(
                    '${product.price.toStringAsFixed(0)} DA',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.amber[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 10, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product.wilaya,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
