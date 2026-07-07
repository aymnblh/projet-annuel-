import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class DatabaseService {
  final CollectionReference _productsRef =
      FirebaseFirestore.instance.collection('products');

  // Récupérer tous les produits
  Stream<List<Product>> get products {
    return _productsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // Ajouter un produit (Gère la liste imageUrls)
  Future<void> addProduct(Product product) async {
    await _productsRef.add(product.toMap());
  }

  // Supprimer un produit
  Future<void> deleteProduct(String productId) async {
    await _productsRef.doc(productId).delete();
  }

  // Incrémenter les vues
  Future<void> incrementViewCount(String productId) async {
    await _productsRef.doc(productId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // Mettre à jour le stock
  Future<void> updateStock(String productId, Map<String, int> newStock) async {
    await _productsRef.doc(productId).update({'stock': newStock});
  }

  // ────────────────────────────────────────────────
  // LEAD TRACKING
  // ────────────────────────────────────────────────

  /// Call [type] = 'call' | 'whatsapp'
  /// Increments the corresponding counter on the product document.
  /// Fire-and-forget: runs in the background without blocking the caller.
  Future<void> incrementLeadCount(String productId, String type) async {
    assert(type == 'call' || type == 'whatsapp',
        'type must be "call" or "whatsapp"');
    final field = type == 'call' ? 'callCount' : 'whatsappCount';
    try {
      await _productsRef.doc(productId).update({
        field: FieldValue.increment(1),
      });
    } catch (e) {
      // Non-blocking: log but don't rethrow
      // ignore: avoid_print
      print('Lead increment error ($type): $e');
    }
  }

  // ────────────────────────────────────────────────
  // REPORT SYSTEM
  // ────────────────────────────────────────────────

  /// Submit a user report for a listing.
  /// [reason] = 'Prix incorrect' | 'Voiture déjà vendue' | 'Annonce frauduleuse' | 'Autre'
  Future<void> reportListing({
    required String productId,
    required String reporterId,
    required String reason,
    String? details,
  }) async {
    // 1. Add to 'reports' collection
    await FirebaseFirestore.instance.collection('reports').add({
      'productId': productId,
      'reporterId': reporterId,
      'reason': reason,
      'details': details ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending', // pending | reviewed | resolved
    });

    // 2. Increment report counter on the product so admin can spot hotspots
    await _productsRef.doc(productId).update({
      'reportCount': FieldValue.increment(1),
    });
  }

  // ────────────────────────────────────────────────
  // SELLER AGGREGATED STATS
  // ────────────────────────────────────────────────

  /// Returns a map { views, calls, whatsapps, listings } aggregated
  /// across all the seller's active listings. Fetched once (not streamed)
  /// for the dashboard summary cards.
  Future<Map<String, int>> fetchSellerStats(String sellerId) async {
    final snap = await _productsRef
        .where('sellerId', isEqualTo: sellerId)
        .get();

    int views = 0, calls = 0, whatsapps = 0;
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      views += (data['viewCount'] as num? ?? 0).toInt();
      calls += (data['callCount'] as num? ?? 0).toInt();
      whatsapps += (data['whatsappCount'] as num? ?? 0).toInt();
    }

    return {
      'views': views,
      'calls': calls,
      'whatsapps': whatsapps,
      'listings': snap.docs.length,
    };
  }
}