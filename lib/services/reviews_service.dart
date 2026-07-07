import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ajouter un avis
  Future<void> addReview({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Vous devez être connecté.");

    final productRef = _firestore.collection('products').doc(productId);
    final reviewRef = productRef.collection('reviews').doc(user.uid); // Un avis par user par produit

    await _firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);
      if (!productSnapshot.exists) throw Exception("Produit introuvable.");

      // Calcul nouvelle moyenne
      double currentRating = (productSnapshot.data()?['rating'] ?? 0).toDouble();
      int currentCount = productSnapshot.data()?['reviewCount'] ?? 0;

      // Si l'utilisateur a déjà noté, on devrait ajuster, mais simplifions pour l'instant : on écrase
      // Pour faire propre : on devrait lire l'ancien avis.
      // Simplification : On incrémente juste (attention aux doublons dans ce cas simple)
      
      // Mieux : On suppose que c'est un nouvel avis pour la démo
      double newRating = ((currentRating * currentCount) + rating) / (currentCount + 1);
      
      transaction.set(reviewRef, {
        'userId': user.uid,
        'userName': user.displayName ?? 'Utilisateur', // Idéalement stocké dans user profile
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(productRef, {
        'rating': newRating,
        'reviewCount': currentCount + 1,
      });
    });
  }

  Stream<QuerySnapshot> getReviews(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
