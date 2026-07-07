import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for tracking recently viewed products
class RecentlyViewedService {
  static const int maxItems = 20;

  /// Track a product view
  /// 
  /// Silently fails on error to not disrupt user experience
  static Future<void> trackView(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recentlyViewed')
          .doc(productId)
          .set({
        'viewedAt': FieldValue.serverTimestamp(),
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Track view timed out for product: $productId');
          throw TimeoutException('Track view timeout');
        },
      );

      // Keep only last 20 items (non-blocking)
      _cleanupOldViews(user.uid).catchError((e) {
        debugPrint('Cleanup failed (non-critical): $e');
      });
    } on TimeoutException catch (e) {
      debugPrint('Timeout tracking view: $e');
      // Silently fail - not critical for user experience
    } on FirebaseException catch (e) {
      debugPrint('Firebase error tracking view: ${e.code} - ${e.message}');
      // Silently fail - not critical for user experience
    } catch (e) {
      debugPrint('Error tracking view: $e');
    }
  }

  /// Cleanup old views to maintain limit
  static Future<void> _cleanupOldViews(String userId) async {
    try {
      final views = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('recentlyViewed')
          .orderBy('viewedAt', descending: true)
          .get()
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Cleanup query timed out');
          throw TimeoutException('Cleanup timeout');
        },
      );

      if (views.docs.length > maxItems) {
        final batch = FirebaseFirestore.instance.batch();
        final docsToDelete = views.docs.skip(maxItems).toList();
        
        // Firestore batch limit is 500 operations
        if (docsToDelete.length > 500) {
          debugPrint('Warning: Too many docs to delete in one batch (${docsToDelete.length})');
          // Only delete first 500
          for (var i = 0; i < 500; i++) {
            batch.delete(docsToDelete[i].reference);
          }
        } else {
          for (var doc in docsToDelete) {
            batch.delete(doc.reference);
          }
        }
        
        await batch.commit().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('Batch commit timed out');
            throw TimeoutException('Batch commit timeout');
          },
        );
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout cleaning up views: $e');
    } on FirebaseException catch (e) {
      debugPrint('Firebase error cleaning up views: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('Error cleaning up views: $e');
    }
  }

  /// Get recently viewed product IDs stream
  static Stream<List<String>> getRecentlyViewed() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('recentlyViewed')
        .orderBy('viewedAt', descending: true)
        .limit(maxItems)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.id).toList());
  }

  /// Clear all viewing history
  static Future<void> clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final views = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recentlyViewed')
          .get();

      for (var doc in views.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  /// Get count of recently viewed items
  static Future<int> getViewCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recentlyViewed')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting view count: $e');
      return 0;
    }
  }
}
