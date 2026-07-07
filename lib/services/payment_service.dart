import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  // Simuler un paiement avec carte Edahabia ou CIB
  // Dans un cas réel, on appellerait ici l'API de Chargily, Satim, ou Stripe
  Future<bool> processPayment({
    required double amount,
    required String method, // 'edahabia' ou 'cib'
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) async {
    // SIMULATION : Délai réseau artificiel
    await Future.delayed(const Duration(seconds: 2));

    // Validation basique (Simulation)
    if (cardNumber.length < 16) throw Exception("Numéro de carte invalide");
    if (cvv.length < 3) throw Exception("Code CVV invalide");

    // Succès aléatoire (95% de chance de succès pour le test)
    // return Random().nextBool(); 
    return true; 
  }

  // Appliquer le boost au produit après paiement réussi
  Future<void> boostProduct({required String productId, required int days}) async {
    final expiresAt = DateTime.now().add(Duration(days: days));
    
    await FirebaseFirestore.instance.collection('products').doc(productId).update({
      'isBoosted': true,
      'boostExpiresAt': expiresAt,
      // On peut aussi ajouter un champ 'boostedAt' pour le tri secondaire
      'boostExpiresAt': expiresAt,
      'boostedAt': FieldValue.serverTimestamp(),
    });
  }

  // Appliquer le badge Urgent (Achat unique ou durée illimitée sur l'annonce)
  Future<void> makeUrgent({required String productId}) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).update({
      'isUrgent': true,
    });
  }

  // Enregistrer une demande de sponsoring Meta
  Future<void> requestMetaSponsorship({
    required String productId,
    required String uid,
    required double budget,
    required int durationdays,
    required List<String> platforms, // ['facebook', 'instagram']
  }) async {
    await FirebaseFirestore.instance.collection('sponsorship_requests').add({
      'productId': productId,
      'userId': uid,
      'budget': budget,
      'durationDays': durationdays,
      'platforms': platforms,
      'status': 'pending', // pending, active, completed, rejected
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
