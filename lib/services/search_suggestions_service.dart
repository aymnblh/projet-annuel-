import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/search_history_service.dart';

/// Service for generating search suggestions
class SearchSuggestionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SearchHistoryService _historyService = SearchHistoryService();

  /// Get search suggestions based on query
  /// 
  /// Combines:
  /// - User's recent searches
  /// - Popular product brands
  /// - Product models
  /// - Fuzzy matching
  Future<List<SearchSuggestion>> getSuggestions(String query) async {
    if (query.trim().isEmpty) {
      // Return recent searches if no query
      final recentSearches = await _historyService.getRecentSearches(limit: 5);
      return recentSearches
          .map((q) => SearchSuggestion(
                text: q,
                type: SuggestionType.recent,
                icon: 'history',
              ))
          .toList();
    }

    final suggestions = <SearchSuggestion>[];
    final lowerQuery = query.toLowerCase().trim();

    try {
      // 1. Get matching brands
      final brandSuggestions = await _getBrandSuggestions(lowerQuery);
      suggestions.addAll(brandSuggestions);

      // 2. Get matching product titles
      final productSuggestions = await _getProductSuggestions(lowerQuery);
      suggestions.addAll(productSuggestions);

      // 3. Add user's matching recent searches
      final recentSearches = await _historyService.getRecentSearches(limit: 10);
      for (var search in recentSearches) {
        if (search.toLowerCase().contains(lowerQuery) && 
            !suggestions.any((s) => s.text.toLowerCase() == search.toLowerCase())) {
          suggestions.add(SearchSuggestion(
            text: search,
            type: SuggestionType.recent,
            icon: 'history',
          ));
        }
      }

      // Remove duplicates and limit
      final uniqueSuggestions = <String, SearchSuggestion>{};
      for (var suggestion in suggestions) {
        final key = suggestion.text.toLowerCase();
        if (!uniqueSuggestions.containsKey(key)) {
          uniqueSuggestions[key] = suggestion;
        }
      }

      // Sort by relevance (exact match first, then starts with, then contains)
      final sortedSuggestions = uniqueSuggestions.values.toList();
      sortedSuggestions.sort((a, b) {
        final aLower = a.text.toLowerCase();
        final bLower = b.text.toLowerCase();
        
        // Exact match
        if (aLower == lowerQuery) return -1;
        if (bLower == lowerQuery) return 1;
        
        // Starts with
        if (aLower.startsWith(lowerQuery) && !bLower.startsWith(lowerQuery)) return -1;
        if (bLower.startsWith(lowerQuery) && !aLower.startsWith(lowerQuery)) return 1;
        
        // Alphabetical
        return aLower.compareTo(bLower);
      });

      return sortedSuggestions.take(10).toList();
    } catch (e) {
      print('Error getting suggestions: $e');
      return [];
    }
  }

  /// Get brand suggestions
  Future<List<SearchSuggestion>> _getBrandSuggestions(String query) async {
    try {
      // Predefined list of popular car brands
      const brands = [
        'Renault', 'Peugeot', 'Volkswagen', 'Mercedes', 'BMW', 'Audi',
        'Toyota', 'Hyundai', 'Kia', 'Nissan', 'Ford', 'Chevrolet',
        'Fiat', 'Seat', 'Skoda', 'Opel', 'Citroën', 'Dacia',
      ];

      return brands
          .where((brand) => brand.toLowerCase().contains(query))
          .map((brand) => SearchSuggestion(
                text: brand,
                type: SuggestionType.brand,
                icon: 'car',
              ))
          .toList();
    } catch (e) {
      print('Error getting brand suggestions: $e');
      return [];
    }
  }

  /// Get product title suggestions
  Future<List<SearchSuggestion>> _getProductSuggestions(String query) async {
    try {
      // Search products by title (limited query for performance)
      final snapshot = await _firestore
          .collection('products')
          .where('isApproved', isEqualTo: true)
          .where('isSold', isEqualTo: false)
          .limit(50)
          .get();

      final suggestions = <SearchSuggestion>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = (data['title'] as String?) ?? '';
        final brand = (data['brand'] as String?) ?? '';
        final model = (data['model'] as String?) ?? '';

        // Check if title, brand, or model contains query
        if (title.toLowerCase().contains(query)) {
          suggestions.add(SearchSuggestion(
            text: title,
            type: SuggestionType.product,
            icon: 'search',
            subtitle: brand.isNotEmpty ? brand : null,
          ));
        } else if (model.toLowerCase().contains(query) && model.isNotEmpty) {
          suggestions.add(SearchSuggestion(
            text: model,
            type: SuggestionType.model,
            icon: 'car',
            subtitle: brand,
          ));
        }
      }

      return suggestions.take(5).toList();
    } catch (e) {
      print('Error getting product suggestions: $e');
      return [];
    }
  }

  /// Get popular searches (global)
  Future<List<String>> getPopularSearches({int limit = 5}) async {
    // This would ideally come from analytics or aggregated data
    // For now, return predefined popular searches
    return [
      'Golf 7',
      'Clio 4',
      'Polo',
      'Symbol',
      'Logan',
    ];
  }
}

/// Search suggestion model
class SearchSuggestion {
  final String text;
  final SuggestionType type;
  final String icon;
  final String? subtitle;

  SearchSuggestion({
    required this.text,
    required this.type,
    required this.icon,
    this.subtitle,
  });
}

/// Suggestion type enum
enum SuggestionType {
  recent,   // From user's search history
  brand,    // Car brand
  model,    // Car model
  product,  // Product title
  popular,  // Popular search
}
