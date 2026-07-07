import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

/// Service for finding similar products based on multiple criteria
class SimilarProductsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get similar products for a given product
  /// 
  /// Uses weighted similarity scoring:
  /// - Category: 40%
  /// - Brand: 30%
  /// - Price: 20%
  /// - Year: 10%
  /// 
  /// Returns empty list on error with graceful fallback
  Future<List<Product>> getSimilarProducts(Product product, {int limit = 5}) async {
    try {
      // First, get products from same category (most important filter)
      Query query = _firestore
          .collection('products')
          .where('category', isEqualTo: product.category)
          .where('isApproved', isEqualTo: true)
          .where('isSold', isEqualTo: false)
          .limit(20); // Get more than needed for scoring

      final snapshot = await query.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Similar products query timed out');
          throw TimeoutException('Query timeout');
        },
      );
      
      // Convert to products and exclude current product
      final products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((p) => p.id != product.id)
          .toList();

      if (products.isEmpty) {
        // Fallback: Try by brand if no category matches
        if (product.brand != null && product.brand!.isNotEmpty) {
          print('No similar products in category, trying by brand...');
          return await getSimilarByBrand(
            product.brand!,
            product.id,
            limit: limit,
          );
        }
        return [];
      }

      // Calculate similarity scores
      final scoredProducts = products.map((p) {
        final score = _calculateSimilarityScore(product, p);
        return _ScoredProduct(p, score);
      }).toList();

      // Sort by score descending
      scoredProducts.sort((a, b) => b.score.compareTo(a.score));

      // Return top N products
      return scoredProducts
          .take(limit)
          .map((sp) => sp.product)
          .toList();
    } on TimeoutException catch (e) {
      print('Timeout getting similar products: $e');
      // Try simpler query as fallback
      try {
        return await getSimilarByCategory(
          product.category,
          product.id,
          limit: limit,
        );
      } catch (fallbackError) {
        print('Fallback also failed: $fallbackError');
        return [];
      }
    } on FirebaseException catch (e) {
      print('Firebase error getting similar products: ${e.code} - ${e.message}');
      // Try fallback for specific errors
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        try {
          return await getSimilarByCategory(
            product.category,
            product.id,
            limit: limit,
          );
        } catch (fallbackError) {
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Error getting similar products: $e');
      return [];
    }
  }

  /// Calculate similarity score between two products
  /// Returns a score between 0.0 and 1.0
  double _calculateSimilarityScore(Product reference, Product candidate) {
    double score = 0.0;

    // 1. Category Match (40% weight)
    if (reference.category == candidate.category) {
      score += 0.4;
    }

    // 2. Brand Match (30% weight)
    if (reference.brand != null && 
        candidate.brand != null && 
        reference.brand!.toLowerCase() == candidate.brand!.toLowerCase()) {
      score += 0.3;
    }

    // 3. Price Match (20% weight)
    // Within ±20% = full score, scales down linearly
    final priceDiff = (reference.price - candidate.price).abs();
    final priceThreshold = reference.price * 0.2; // 20%
    
    if (priceDiff <= priceThreshold) {
      final priceScore = 1.0 - (priceDiff / priceThreshold);
      score += 0.2 * priceScore;
    }

    // 4. Year Match (10% weight)
    // Within ±3 years = full score, scales down linearly
    if (reference.year != null && candidate.year != null) {
      final refYear = int.tryParse(reference.year!);
      final candYear = int.tryParse(candidate.year!);
      
      if (refYear != null && candYear != null) {
        final yearDiff = (refYear - candYear).abs();
        const yearThreshold = 3;
        
        if (yearDiff <= yearThreshold) {
          final yearScore = 1.0 - (yearDiff / yearThreshold);
          score += 0.1 * yearScore;
        }
      }
    }

    return score;
  }

  /// Get similar products by brand only
  /// Fallback method if main algorithm returns few results
  Future<List<Product>> getSimilarByBrand(
    String brand, 
    String excludeId, {
    int limit = 5,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('brand', isEqualTo: brand)
          .where('isApproved', isEqualTo: true)
          .where('isSold', isEqualTo: false)
          .limit(limit + 1) // +1 to account for excluded product
          .get();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((p) => p.id != excludeId)
          .take(limit)
          .toList();
    } catch (e) {
      print('Error getting similar by brand: $e');
      return [];
    }
  }

  /// Get similar products by category only
  /// Another fallback method
  Future<List<Product>> getSimilarByCategory(
    String category,
    String excludeId, {
    int limit = 5,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .where('isApproved', isEqualTo: true)
          .where('isSold', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit + 1)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .where((p) => p.id != excludeId)
          .take(limit)
          .toList();
    } catch (e) {
      print('Error getting similar by category: $e');
      return [];
    }
  }
}

/// Internal class for storing products with their similarity scores
class _ScoredProduct {
  final Product product;
  final double score;

  _ScoredProduct(this.product, this.score);
}
