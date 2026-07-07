import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'product_card.dart';

class ProductSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Rechercher...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) return const SizedBox.shrink();

    // Recherche simple (contient la chaîne, insensible à la casse serait idéal mais difficile en simple query Firestore)
    // Ici on va fetcher et filtrer client-side pour la démo "Fuzzy" simple
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').limit(100).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final allProducts = snapshot.data!.docs.map((d) => Product.fromFirestore(d)).toList();
        final results = allProducts.where((p) => 
          p.title.toLowerCase().contains(query.toLowerCase()) || 
          p.description.toLowerCase().contains(query.toLowerCase())
        ).toList();

        // 🚀 SMART BOOST : Trie pour mettre les "isBoosted" en premier !
        results.sort((a, b) {
          if (a.isBoosted && !b.isBoosted) return -1;
          if (!a.isBoosted && b.isBoosted) return 1;
          return 0;
        });

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 60, color: Colors.grey),
                const SizedBox(height: 10),
                Text("Aucun résultat pour \"$query\"", style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.75, mainAxisSpacing: 10, crossAxisSpacing: 10
          ),
          itemCount: results.length,
          itemBuilder: (ctx, i) => ProductCard(product: results[i]),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Suggestions rapides si vide
    if (query.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Suggestions populaires", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                _suggestionChip(context, "Iphone"),
                _suggestionChip(context, "Samsung"),
                _suggestionChip(context, "Golf 7"),
                _suggestionChip(context, "Appartement"),
                _suggestionChip(context, "Villa"),
                _suggestionChip(context, "PlayStation 5"),
              ],
            )
          ],
        ),
      );
    }
    
    // Autocomplétion basique (même logique que results pour l'instant)
    return buildResults(context);
  }

  Widget _suggestionChip(BuildContext context, String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.grey[100],
      onPressed: () {
        query = label;
        showResults(context);
      },
    );
  }
}