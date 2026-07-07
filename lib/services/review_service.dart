import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/review.dart';
import '../models/product.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== SUBMIT REVIEW ====================
  
  /// Submit a new review (isApproved: false by default)
  static Future<String?> submitReview({
    required String productId,
    required String sellerId,
    required int rating,
    required String comment,
    List<String> photos = const [],
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous';
      final userPhoto = userDoc.data()?['photoUrl'];

      // Create review
      final reviewData = {
        'productId': productId,
        'sellerId': sellerId,
        'userId': user.uid,
        'userName': userName,
        'userPhoto': userPhoto,
        'rating': rating,
        'comment': comment,
        'photos': photos,
        'createdAt': FieldValue.serverTimestamp(),
        'isApproved': false, // Requires admin approval
        'helpfulCount': 0,
        'reportCount': 0,
        'isFlagged': false,
        'isVerifiedPurchase': false,
      };

      final docRef = await _firestore.collection('reviews').add(reviewData);
      
      debugPrint('Review submitted: ${docRef.id} (pending approval)');
      return docRef.id;
    } catch (e) {
      debugPrint('Error submitting review: $e');
      return null;
    }
  }

  // ==================== GET REVIEWS ====================
  
  /// Get approved reviews for a product
  static Stream<List<Review>> getProductReviews(String productId) {
    return _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .where('isApproved', isEqualTo: true) // Only approved
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get approved reviews for a seller
  static Stream<List<Review>> getSellerReviews(String sellerId) {
    return _firestore
        .collection('reviews')
        .where('sellerId', isEqualTo: sellerId)
        .where('isApproved', isEqualTo: true) // Only approved
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get pending reviews (admin only)
  static Stream<List<Review>> getPendingReviews() {
    return _firestore
        .collection('reviews')
        .where('isApproved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get flagged reviews (admin only)
  static Stream<List<Review>> getFlaggedReviews() {
    return _firestore
        .collection('reviews')
        .where('isFlagged', isEqualTo: true)
        .orderBy('flaggedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // ==================== ADMIN ACTIONS ====================
  
  /// Approve a review (admin only)
  static Future<bool> approveReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'isApproved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update product rating after approval
      final review = await _firestore.collection('reviews').doc(reviewId).get();
      if (review.exists) {
        final productId = review.data()?['productId'];
        if (productId != null) {
          await updateProductRating(productId);
        }
      }

      debugPrint('Review approved: $reviewId');
      return true;
    } catch (e) {
      debugPrint('Error approving review: $e');
      return false;
    }
  }

  /// Reject/Delete a review (admin only)
  static Future<bool> rejectReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).delete();
      debugPrint('Review rejected/deleted: $reviewId');
      return true;
    } catch (e) {
      debugPrint('Error rejecting review: $e');
      return false;
    }
  }

  /// Delete a review (admin only)
  static Future<bool> deleteReview(String reviewId) async {
    try {
      // Get review data before deleting
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      final productId = reviewDoc.data()?['productId'];

      await _firestore.collection('reviews').doc(reviewId).delete();

      // Update product rating after deletion
      if (productId != null) {
        await updateProductRating(productId);
      }

      debugPrint('Review deleted: $reviewId');
      return true;
    } catch (e) {
      debugPrint('Error deleting review: $e');
      return false;
    }
  }

  // ==================== SELLER ACTIONS ====================
  
  /// Add seller response to a review
  static Future<bool> addSellerResponse(String reviewId, String response) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('reviews').doc(reviewId).update({
        'sellerResponse': response,
        'sellerResponseDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Seller response added to review: $reviewId');
      return true;
    } catch (e) {
      debugPrint('Error adding seller response: $e');
      return false;
    }
  }

  /// Flag a review for admin review
  static Future<bool> flagReview(String reviewId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('reviews').doc(reviewId).update({
        'isFlagged': true,
        'flagReason': reason,
        'flaggedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Review flagged: $reviewId - Reason: $reason');
      return true;
    } catch (e) {
      debugPrint('Error flagging review: $e');
      return false;
    }
  }

  /// Unflag a review (admin only)
  static Future<bool> unflagReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'isFlagged': false,
        'flagReason': null,
        'flaggedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Review unflagged: $reviewId');
      return true;
    } catch (e) {
      debugPrint('Error unflagging review: $e');
      return false;
    }
  }

  // ==================== ENGAGEMENT ====================
  
  /// Mark review as helpful
  static Future<bool> markReviewHelpful(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'helpfulCount': FieldValue.increment(1),
      });

      debugPrint('Review marked as helpful: $reviewId');
      return true;
    } catch (e) {
      debugPrint('Error marking review as helpful: $e');
      return false;
    }
  }

  /// Report a review
  static Future<bool> reportReview(String reviewId) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'reportCount': FieldValue.increment(1),
      });

      debugPrint('Review reported: $reviewId');
      return true;
    } catch (e) {
      debugPrint('Error reporting review: $e');
      return false;
    }
  }

  // ==================== RATING CALCULATIONS ====================
  
  /// Update product rating based on approved reviews
  static Future<void> updateProductRating(String productId) async {
    try {
      // Get all approved reviews for this product
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('isApproved', isEqualTo: true)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        // No reviews, reset rating
        await _firestore.collection('products').doc(productId).update({
          'averageRating': 0.0,
          'reviewCount': 0,
          'ratingDistribution': {
            '1': 0,
            '2': 0,
            '3': 0,
            '4': 0,
            '5': 0,
          },
        });
        return;
      }

      // Calculate average and distribution
      int totalRating = 0;
      Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var doc in reviewsSnapshot.docs) {
        final rating = doc.data()['rating'] as int;
        totalRating += rating;
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }

      final averageRating = totalRating / reviewsSnapshot.docs.length;

      // Update product
      await _firestore.collection('products').doc(productId).update({
        'averageRating': averageRating,
        'reviewCount': reviewsSnapshot.docs.length,
        'ratingDistribution': {
          '1': distribution[1],
          '2': distribution[2],
          '3': distribution[3],
          '4': distribution[4],
          '5': distribution[5],
        },
      });

      debugPrint('Product rating updated: $productId - Avg: $averageRating');
    } catch (e) {
      debugPrint('Error updating product rating: $e');
    }
  }

  /// Update seller rating based on approved reviews
  static Future<void> updateSellerRating(String sellerId) async {
    try {
      // Get all approved reviews for this seller
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('sellerId', isEqualTo: sellerId)
          .where('isApproved', isEqualTo: true)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        // No reviews, reset rating
        await _firestore.collection('users').doc(sellerId).update({
          'sellerRating': 0.0,
          'sellerReviewCount': 0,
        });
        return;
      }

      // Calculate average
      int totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += doc.data()['rating'] as int;
      }

      final averageRating = totalRating / reviewsSnapshot.docs.length;

      // Update seller
      await _firestore.collection('users').doc(sellerId).update({
        'sellerRating': averageRating,
        'sellerReviewCount': reviewsSnapshot.docs.length,
      });

      debugPrint('Seller rating updated: $sellerId - Avg: $averageRating');
    } catch (e) {
      debugPrint('Error updating seller rating: $e');
    }
  }

  // ==================== VALIDATION ====================
  
  /// Check if user can review this product
  static Future<bool> canUserReview(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if user already reviewed this product
      final existingReview = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existingReview.docs.isNotEmpty) {
        debugPrint('User already reviewed this product');
        return false;
      }

      // Check if user owns this product
      final product = await _firestore.collection('products').doc(productId).get();
      if (product.data()?['sellerId'] == user.uid) {
        debugPrint('User cannot review their own product');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking if user can review: $e');
      return false;
    }
  }

  /// Get review count for a product
  static Future<int> getReviewCount(String productId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .where('isApproved', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting review count: $e');
      return 0;
    }
  }

  /// Get average rating for a product
  static Future<double> getAverageRating(String productId) async {
    try {
      final product = await _firestore.collection('products').doc(productId).get();
      return (product.data()?['averageRating'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('Error getting average rating: $e');
      return 0.0;
    }
  }
}
