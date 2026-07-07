import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  // Récupérer les données utilisateur
  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    // notifyListeners(); // Éviter trop de rebuilds si pas nécessaire ici

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>;
        // Charger les favoris et intérêts
        _loadFavorites(user.uid);
        _loadInterests(_userData!);
      }
    } catch (e) {
      print("Erreur UserProvider: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  // Mettre à jour localement (optimistic update)
  void updateLocalData(Map<String, dynamic> newData) {
    if (_userData == null) return;
    _userData!.addAll(newData);
    notifyListeners();
  }

  // Mettre à jour profil (Firestore + Local)
  Future<void> updateProfile({String? name, String? phone, String? wilaya, String? coverImageUrl, String? whatsapp}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (wilaya != null) updates['wilaya'] = wilaya;
      if (coverImageUrl != null) updates['coverImageUrl'] = coverImageUrl;
      if (whatsapp != null) updates['whatsapp'] = whatsapp;

      if (updates.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);
        updateLocalData(updates);
        // Si le nom change, on peut aussi vouloir update le auth profile, mais optionnel
      }
    } catch (e) {
      print("Erreur Update Profile: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // --- GESTION DES INTÉRÊTS (RECOMMANDATION) ---
  Map<String, int> _interests = {};
  Map<String, int> get interests => _interests;

  Future<void> logInterest(String category, {int weight = 1}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Mise à jour Optimiste
    _interests[category] = (_interests[category] ?? 0) + weight;
    // notifyListeners(); // Pas besoin de redraw tout l'app pour ça, sauf si le feed écoute

    try {
      // On sauvegarde dans un champ Map 'interests'
      // Note: Firestore ne permet pas d'incrémenter une map imbriquée facilement avec FieldValue.increment si la clé est dynamique dans un seul path
      // Mais on peut utiliser Dot Notation : 'interests.Vêtements'
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'interests.$category': FieldValue.increment(weight)
      });
    } catch (e) {
      print("Erreur logInterest: $e");
    }
  }

  // --- GESTION DES FAVORIS ---
  List<String> _favoriteIds = [];
  List<String> get favoriteIds => _favoriteIds;

  Future<void> _loadFavorites(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('favorites').get();
      _favoriteIds = snap.docs.map((d) => d.id).toList();
      notifyListeners();
    } catch (e) {
      print("Erreur chargement favoris: $e");
    }
  }

  // Charger les intérêts lors du fetch
  void _loadInterests(Map<String, dynamic> data) {
    if (data.containsKey('interests')) {
      final i = data['interests'];
      if (i is Map) {
        _interests = Map<String, int>.from(i.map((k, v) => MapEntry(k.toString(), (v as num).toInt())));
      }
    }
  }

  // ... (Suite du code existant isFavorite, toggleFavorite)
  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  Future<void> toggleFavorite(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Optimistic Update
    bool isCurrentlyFav = _favoriteIds.contains(productId);
    if (isCurrentlyFav) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();

    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('favorites').doc(productId);
      if (isCurrentlyFav) {
        await ref.delete();
      } else {
        await ref.set({'addedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      if (isCurrentlyFav) {
        _favoriteIds.add(productId);
      } else {
        _favoriteIds.remove(productId);
      }
      notifyListeners();
      print("Erreur Toggle Favorite: $e");
    }
  }
  
  // --- GESTION PRO / BOUTIQUE ---
  Future<void> upgradeToPro(Map<String, dynamic> storeData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final Map<String, dynamic> updates = {
        'isPro': true,
        'proExpiresAt': DateTime.now().add(const Duration(days: 30)), // 1 mois offert/payé
        ...storeData, // storeName, storeDescription, storeLocation, etc.
      };

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);
      
      // Mise à jour locale
      if (_userData != null) {
        _userData!.addAll(updates);
      } else {
        _userData = updates;
      }
      notifyListeners();
    } catch (e) {
      print("Erreur upgradeToPro: $e");
      rethrow;
    }
  }

  // Helper pour vérifier si pro
  bool get isPro => _userData != null && (_userData!['isPro'] == true);

  // --- VERIFICATION (BLUE CHECK) ---
  bool get isVerified => _userData != null && (_userData!['isVerified'] == true);
  bool get isAdmin => _userData != null && (_userData!['isAdmin'] == true); // ADMIN CHECK
  String get verificationStatus => _userData != null ? (_userData!['verificationStatus'] ?? 'none') : 'none'; // none, pending, verified, rejected

  Future<void> requestVerification(String idUrl, String selfieUrl) async {
     final user = FirebaseAuth.instance.currentUser;
     if (user == null) return;

     try {
       await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
         'verificationStatus': 'pending',
         'verificationRequestedAt': FieldValue.serverTimestamp(),
         'verificationIdUrl': idUrl,
         'verificationSelfieUrl': selfieUrl,
       });
       
       // Update Local
       if (_userData != null) {
         _userData!['verificationStatus'] = 'pending';
         _userData!['verificationIdUrl'] = idUrl;
         _userData!['verificationSelfieUrl'] = selfieUrl;
       }
       notifyListeners();
     } catch(e) {
       print("Erreur requestVerification: $e");
       rethrow;
     }
  }
  // --- RECHERCHES SAUVEGARDÉES (ALERTES) ---
  Future<void> saveSearchAlert(Map<String, dynamic> filters, String label) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('search_alerts').add({
        'filters': filters,
        'label': label,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      notifyListeners();
    } catch (e) {
      print("Erreur saveSearchAlert: $e");
      rethrow;
    }
  }

  Future<void> deleteSearchAlert(String alertId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('search_alerts').doc(alertId).delete();
      notifyListeners();
    } catch (e) {
      print("Erreur deleteSearchAlert: $e");
    }
  }
  // --- AVIS VENDEURS (REVIEWS) ---
  Future<void> addSellerReview(String sellerId, double rating, String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Ajouter l'avis dans la sous-collection du vendeur
      await FirebaseFirestore.instance.collection('users').doc(sellerId).collection('reviews').add({
        'reviewerId': user.uid,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Mettre à jour la moyenne du vendeur (Aggregation ou FieldValue)
      // Pour faire simple et scalable, on peut utiliser une cloud function normalement, 
      // mais ici on va lire et update (attention race condition en prod, ok pour MVP)
      
      final sellerRef = FirebaseFirestore.instance.collection('users').doc(sellerId);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
         DocumentSnapshot snapshot = await transaction.get(sellerRef);
         if (!snapshot.exists) return;
         
         double currentRating = (snapshot.data() as Map)['rating']?.toDouble() ?? 0.0;
         int reviewCount = (snapshot.data() as Map)['reviewCount']?.toInt() ?? 0;
         
         double newRating = ((currentRating * reviewCount) + rating) / (reviewCount + 1);
         
         transaction.update(sellerRef, {
           'rating': newRating,
           'reviewCount': reviewCount + 1
         });
      });

    } catch (e) {
      print("Erreur addSellerReview: $e");
      rethrow;
    }
  }
}
