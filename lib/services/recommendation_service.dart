import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';

/// Service for generating product recommendations
class RecommendationService {
  /// Get similar cars based on the given product
  /// 
  /// Matching criteria (weighted):
  /// - Same brand: +50 points
  /// - Price within ±20%: +30 points
  /// - Year within ±2 years: +20 points
  /// - Same category: +40 points
  /// - Same wilaya: +10 points
  /// - Same fuel type: +15 points
  /// - Same gearbox: +10 points
  static Future<List<Product>> getSimilarCars(
    Product product, {
    int limit = 5,
  }) async {
    try {
      // Calculate price range (±20%)
      final minPrice = product.price * 0.8;
      final maxPrice = product.price * 1.2;

      // Calculate year range (±2 years)
      final currentYear = int.tryParse(product.year ?? '') ?? 2020;
      final minYear = currentYear - 2;
      final maxYear = currentYear + 2;

      // Build query
      Query query = FirebaseFirestore.instance
          .collection('products')
          .where('isApproved', isEqualTo: true)
          .where('category', isEqualTo: product.category)
          .limit(20); // Get more than needed for scoring

      final snapshot = await query.get();

      // Convert to products and filter out current product
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((p) => p.id != product.id)
          .toList();

      // Score each product
      final scoredProducts = products.map((p) {
        int score = 0;

        // Same brand (highest weight)
        if (p.brand != null &&
            product.brand != null &&
            p.brand!.toLowerCase() == product.brand!.toLowerCase()) {
          score += 50;
        }

        // Price similarity
        if (p.price >= minPrice && p.price <= maxPrice) {
          score += 30;
          // Bonus for closer prices
          final priceDiff = (p.price - product.price).abs();
          final priceRange = product.price * 0.2;
          if (priceDiff < priceRange * 0.5) {
            score += 10; // Very close price
          }
        }

        // Year similarity
        if (p.year != null && product.year != null) {
          final pYear = int.tryParse(p.year!);
          if (pYear != null && pYear >= minYear && pYear <= maxYear) {
            score += 20;
            // Bonus for exact year match
            if (p.year == product.year) {
              score += 10;
            }
          }
        }

        // Same category (already filtered, but add points)
        score += 40;

        // Same wilaya (local preference)
        if (p.wilaya == product.wilaya) {
          score += 10;
        }

        // Same fuel type
        if (p.fuel != null &&
            product.fuel != null &&
            p.fuel == product.fuel) {
          score += 15;
        }

        // Same gearbox
        if (p.gearbox != null &&
            product.gearbox != null &&
            p.gearbox == product.gearbox) {
          score += 10;
        }

        // Boost bonus (boosted items are likely higher quality)
        if (p.isBoosted) {
          score += 5;
        }

        return MapEntry(p, score);
      }).toList();

      // Sort by score (descending)
      scoredProducts.sort((a, b) => b.value.compareTo(a.value));

      // Return top N products
      return scoredProducts
          .take(limit)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      debugPrint('Error getting similar cars: $e');
      return [];
    }
  }

  /// Get recommendations based on user's browsing history
  static Future<List<Product>> getPersonalizedRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    try {
      // Get user's recently viewed products
      final viewedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('recentlyViewed')
          .orderBy('viewedAt', descending: true)
          .limit(5)
          .get();

      if (viewedSnapshot.docs.isEmpty) {
        return _getFallbackRecommendations(limit);
      }

      // Get the products
      final viewedProductIds = viewedSnapshot.docs.map((d) => d.id).toList();
      final viewedProducts = <Product>[];

      for (var id in viewedProductIds) {
        final doc = await FirebaseFirestore.instance
            .collection('products')
            .doc(id)
            .get();
        if (doc.exists) {
          viewedProducts.add(Product.fromFirestore(doc));
        }
      }

      if (viewedProducts.isEmpty) {
        return _getFallbackRecommendations(limit);
      }

      // Get similar cars for each viewed product
      final allSimilar = <Product>[];
      for (var product in viewedProducts) {
        final similar = await getSimilarCars(product, limit: 3);
        allSimilar.addAll(similar);
      }

      // Remove duplicates and return
      final uniqueProducts = <String, Product>{};
      for (var product in allSimilar) {
        uniqueProducts[product.id] = product;
      }

      return uniqueProducts.values.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting personalized recommendations: $e');
      return _getFallbackRecommendations(limit);
    }
  }

  /// Fallback recommendations (trending/recent)
  static Future<List<Product>> _getFallbackRecommendations(int limit) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting fallback recommendations: $e');
      return [];
    }
  }

  /// Get trending cars (most viewed in last 7 days)
  static Future<List<Product>> getTrendingCars({int limit = 10}) async {
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('isApproved', isEqualTo: true)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .orderBy('createdAt', descending: true)
          // Removed duplicate orderBy on viewCount to avoid composite index failure
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting trending cars: $e');
      return [];
    }
  }

  /// Get discovery recommendations — products *outside* the user's usual
  /// preferences. This helps users discover cars they might not have
  /// considered, increasing engagement and broadening their search.
  static Future<List<Product>> getDiscoveryRecommendations(
    String userId, {
    int limit = 5,
  }) async {
    try {
      // 1. Read the user's interest profile
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('interestProfile')
          .doc('current')
          .get();

      if (!profileDoc.exists) {
        return _getFallbackRecommendations(limit);
      }

      final profile = profileDoc.data() as Map<String, dynamic>;
      final topBrands = List<String>.from(profile['topBrands'] ?? []);

      // 2. Query approved products
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50) // fetch a larger pool for filtering
          .get();

      final allProducts =
          snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();

      if (allProducts.isEmpty) {
        return [];
      }

      // 3. Filter OUT the user's top brands
      final topBrandsLower =
          topBrands.map((b) => b.toLowerCase()).toSet();

      final preferredVehicleTypes = List<String>.from(
          profile['preferredVehicleTypes'] ?? []);
      final preferredVTypesLower =
          preferredVehicleTypes.map((v) => v.toLowerCase()).toSet();

      // Score each product — higher score = more "discovery-like"
      final scored = <MapEntry<Product, int>>[];

      for (final p in allProducts) {
        int discoveryScore = 0;

        // Brand NOT in top brands → big boost
        if (p.brand != null &&
            !topBrandsLower.contains(p.brand!.toLowerCase())) {
          discoveryScore += 30;
        }

        // Vehicle type NOT in preferred types → boost
        if (p.vehicleType != null &&
            p.vehicleType!.isNotEmpty &&
            !preferredVTypesLower
                .contains(p.vehicleType!.toLowerCase())) {
          discoveryScore += 20;
        }

        // Different category than most-engaged
        final engagementScores =
            Map<String, dynamic>.from(profile['engagementScores'] ?? {});
        if (engagementScores.isNotEmpty) {
          // Find the user's top category
          final topCategory = engagementScores.entries
              .reduce((a, b) =>
                  (a.value as num) >= (b.value as num) ? a : b)
              .key;
          if (p.category != topCategory) {
            discoveryScore += 15;
          }
        }

        // Boost recently created listings
        if (p.createdAt
            .isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
          discoveryScore += 5;
        }

        // Boosted listings get a small nudge
        if (p.isBoosted) {
          discoveryScore += 5;
        }

        // Only include products with a meaningful discovery score
        if (discoveryScore >= 20) {
          scored.add(MapEntry(p, discoveryScore));
        }
      }

      // Sort by discovery score descending
      scored.sort((a, b) => b.value.compareTo(a.value));

      final result =
          scored.take(limit).map((e) => e.key).toList();

      // Fallback if we couldn't find enough discovery products
      if (result.isEmpty) {
        return _getFallbackRecommendations(limit);
      }

      return result;
    } catch (e) {
      debugPrint('Error getting discovery recommendations: $e');
      return _getFallbackRecommendations(limit);
    }
  }
}
