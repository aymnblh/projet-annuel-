import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing user search history
class SearchHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int _maxHistoryItems = 20;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Add search to history
  Future<void> addSearch({
    required String query,
    int? resultCount,
    Map<String, dynamic>? filters,
  }) async {
    if (_currentUserId == null || query.trim().isEmpty) return;

    try {
      // Add search entry
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('search_history')
          .add({
        'query': query.trim().toLowerCase(),
        'displayQuery': query.trim(), // Keep original case for display
        'timestamp': FieldValue.serverTimestamp(),
        'resultCount': resultCount ?? 0,
        'filters': filters ?? {},
      });

      // Cleanup old entries
      await _cleanupOldSearches();
    } catch (e) {
      print('Error adding search to history: $e');
    }
  }

  /// Get search history stream
  Stream<List<SearchHistoryItem>> getSearchHistory({int limit = 10}) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('search_history')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SearchHistoryItem(
          id: doc.id,
          query: data['displayQuery'] ?? data['query'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          resultCount: data['resultCount'] ?? 0,
          filters: Map<String, dynamic>.from(data['filters'] ?? {}),
        );
      }).toList();
    });
  }

  /// Get recent searches (last 5)
  Future<List<String>> getRecentSearches({int limit = 5}) async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('search_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['displayQuery'] as String? ?? '')
          .where((query) => query.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error getting recent searches: $e');
      return [];
    }
  }

  /// Delete a specific search from history
  Future<void> deleteSearch(String searchId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('search_history')
          .doc(searchId)
          .delete();
    } catch (e) {
      print('Error deleting search: $e');
    }
  }

  /// Clear all search history
  Future<void> clearHistory() async {
    if (_currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('search_history')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing history: $e');
      rethrow;
    }
  }

  /// Cleanup old searches to maintain limit
  Future<void> _cleanupOldSearches() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('search_history')
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.length > _maxHistoryItems) {
        final batch = _firestore.batch();
        final toDelete = snapshot.docs.skip(_maxHistoryItems);

        for (var doc in toDelete) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error cleaning up searches: $e');
    }
  }

  /// Get search count
  Future<int> getSearchCount() async {
    if (_currentUserId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('search_history')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting search count: $e');
      return 0;
    }
  }
}

/// Search history item model
class SearchHistoryItem {
  final String id;
  final String query;
  final DateTime timestamp;
  final int resultCount;
  final Map<String, dynamic> filters;

  SearchHistoryItem({
    required this.id,
    required this.query,
    required this.timestamp,
    required this.resultCount,
    required this.filters,
  });
}
