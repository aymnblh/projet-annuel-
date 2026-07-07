import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Ajouter un produit
  Future<void> addProduct(Map<String, dynamic> productData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('products').add(productData);
      
      // Pas besoin de recharger manuellement si on utilise des Streams dans l'UI
      // Mais on pourrait ajouter une notification de succès ici
    } catch (e) {
      _error = e.toString();
      print("Erreur AddProduct: $e");
      rethrow; // Laisser la vue gérer l'affichage de l'erreur finale
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour un produit
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).update(data);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Supprimer un produit
  Future<void> deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
    } catch (e) {
      print("Erreur DeleteProduct: $e");
      rethrow;
    }
  }
}
