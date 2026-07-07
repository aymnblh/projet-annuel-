import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing user favorites/wishlist
class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String get _currentUserId => _auth.currentUser!.uid;

  /// Add a product to favorites
  Future<void> addToFavorites(String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('favorites')
          .doc(productId)
          .set({
        'productId': productId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  /// Remove a product from favorites
  Future<void> removeFromFavorites(String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('favorites')
          .doc(productId)
          .delete();
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  /// Toggle favorite status (add if not favorite, remove if favorite)
  Future<void> toggleFavorite(String productId) async {
    final isFav = await isFavorite(productId);
    if (isFav) {
      await removeFromFavorites(productId);
    } else {
      await addToFavorites(productId);
    }
  }

  /// Check if a product is in favorites
  Future<bool> isFavorite(String productId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('favorites')
          .doc(productId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  /// Get stream of favorite product IDs
  Stream<List<String>> getFavoriteIds() {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Get stream of favorite products with full details
  Stream<QuerySnapshot> getFavoriteProducts() {
    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  /// Get count of favorites
  Future<int> getFavoritesCount() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('favorites')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }

  /// Clear all favorites (with confirmation)
  Future<void> clearAllFavorites() async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('favorites')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing favorites: $e');
      rethrow;
    }
  }

  /// Batch add multiple products to favorites
  Future<void> addMultipleToFavorites(List<String> productIds) async {
    try {
      final batch = _firestore.batch();
      
      for (var productId in productIds) {
        final ref = _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('favorites')
            .doc(productId);
        
        batch.set(ref, {
          'productId': productId,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error batch adding favorites: $e');
      rethrow;
    }
  }
}
