import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/algolia_service.dart';
import '../widgets/optimized_image.dart';
import '../views/product_details_screen.dart';
import 'dart:async';

/// Enhanced search delegate powered by Algolia REST API
class AlgoliaSearchDelegate extends SearchDelegate<Product?> {
  final List<String> _searchHistory = [];
  Timer? _debounce;

  @override
  String get searchFieldLabel => 'Rechercher une voiture...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.textTheme.bodyLarge?.color),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: GoogleFonts.cairo(
          color: Colors.grey[400],
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildSearchHistory(context);
    }

    return FutureBuilder<List<String>>(
      future: Future.delayed(
        const Duration(milliseconds: 300),
        () => AlgoliaService.getSuggestions(query),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final suggestions = snapshot.data!;

        if (suggestions.isEmpty) {
          return _buildNoSuggestions(context);
        }

        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              leading: const Icon(Icons.search, color: Colors.grey),
              title: Text(
                suggestion,
                style: GoogleFonts.cairo(fontSize: 15),
              ),
              onTap: () {
                query = suggestion;
                _addToHistory(suggestion);
                showResults(context);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyQuery(context);
    }

    _addToHistory(query);

    return FutureBuilder<List<Product>>(
      future: AlgoliaService.searchProducts(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => const ProductCardSkeleton(),
          );
        }

        final products = snapshot.data!;

        if (products.isEmpty) {
          return _buildNoResults(context);
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Text(
                    '${products.length} résultat${products.length > 1 ? 's' : ''}',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(context, products[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () {
        close(context, product);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: OptimizedImage(
                  imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls[0] : '',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(0)} EUR',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 10, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product.wilaya,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 10, 
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600]
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHistory(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: AlgoliaService.getPopularSearches(),
      builder: (context, snapshot) {
        final popularSearches = snapshot.data ?? [];

        return ListView(
          children: [
            if (_searchHistory.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Recherches récentes',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _searchHistory.clear(),
                      child: Text('Effacer', style: GoogleFonts.cairo(fontSize: 13)),
                    ),
                  ],
                ),
              ),
              ..._searchHistory.reversed.take(5).map((term) {
                return ListTile(
                  leading: const Icon(Icons.history, color: Colors.grey),
                  title: Text(term, style: GoogleFonts.cairo()),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _searchHistory.remove(term),
                  ),
                  onTap: () {
                    query = term;
                    showResults(context);
                  },
                );
              }),
              const Divider(),
            ],
            if (popularSearches.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Recherches populaires',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ...popularSearches.map((term) {
                return ListTile(
                  leading: const Icon(Icons.trending_up, color: Colors.orange),
                  title: Text(term, style: GoogleFonts.cairo()),
                  onTap: () {
                    query = term;
                    showResults(context);
                  },
                );
              }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNoSuggestions(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucune suggestion',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'Aucun résultat pour "$query"',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Essayez avec d\'autres mots-clés',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                query = '';
                showSuggestions(context);
              },
              icon: const Icon(Icons.refresh),
              label: Text('Nouvelle recherche', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQuery(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              'Recherchez une voiture',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Marque, modèle, année...',
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  void _addToHistory(String term) {
    if (term.isEmpty) return;
    _searchHistory.remove(term);
    _searchHistory.add(term);
    if (_searchHistory.length > 10) {
      _searchHistory.removeAt(0);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

