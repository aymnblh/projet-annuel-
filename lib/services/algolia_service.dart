import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../models/product.dart';

/// Service for Algolia instant search using REST API
/// This implementation uses direct HTTP calls instead of the algolia package
/// to avoid dependency conflicts
class AlgoliaService {
  static String get _appId => dotenv.env['ALGOLIA_APP_ID'] ?? '';
  static String get _searchKey => dotenv.env['ALGOLIA_SEARCH_KEY'] ?? '';
  static String get _indexName => dotenv.env['ALGOLIA_INDEX_NAME'] ?? 'products';

  static String get _baseUrl =>
      'https://$_appId-dsn.algolia.net/1/indexes/$_indexName';

  /// Search products with optional filters
  static Future<List<Product>> searchProducts(
    String query, {
    Map<String, dynamic>? filters,
    int page = 0,
    int hitsPerPage = 20,
  }) async {
    try {
      final body = {
        'query': query,
        'page': page,
        'hitsPerPage': hitsPerPage,
      };

      // Add filters
      if (filters != null) {
        final facetFilters = <String>[];
        final numericFilters = <String>[];

        // Brand filter
        if (filters['brand'] != null && filters['brand'].isNotEmpty) {
          facetFilters.add('brand:${filters['brand']}');
        }

        // Category filter
        if (filters['category'] != null && filters['category'].isNotEmpty) {
          facetFilters.add('category:${filters['category']}');
        }

        // Wilaya filter
        if (filters['wilaya'] != null && filters['wilaya'].isNotEmpty) {
          facetFilters.add('wilaya:${filters['wilaya']}');
        }

        // Fuel filter
        if (filters['fuel'] != null && filters['fuel'].isNotEmpty) {
          facetFilters.add('fuel:${filters['fuel']}');
        }

        // Gearbox filter
        if (filters['gearbox'] != null && filters['gearbox'].isNotEmpty) {
          facetFilters.add('gearbox:${filters['gearbox']}');
        }

        // Price range
        if (filters['minPrice'] != null) {
          numericFilters.add('price >= ${filters['minPrice']}');
        }
        if (filters['maxPrice'] != null) {
          numericFilters.add('price <= ${filters['maxPrice']}');
        }

        // Year range
        if (filters['minYear'] != null) {
          numericFilters.add('year >= ${filters['minYear']}');
        }
        if (filters['maxYear'] != null) {
          numericFilters.add('year <= ${filters['maxYear']}');
        }

        if (facetFilters.isNotEmpty) {
          body['facetFilters'] = facetFilters;
        }
        if (numericFilters.isNotEmpty) {
          body['numericFilters'] = numericFilters;
        }
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/query'),
        headers: {
          'X-Algolia-API-Key': _searchKey,
          'X-Algolia-Application-Id': _appId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = data['hits'] as List;

        return hits
            .map((hit) => Product.fromMap(
                  hit as Map<String, dynamic>,
                  hit['objectID'] as String,
                ))
            .toList();
      } else {
        debugPrint('Algolia search error: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Algolia search error: $e');
      return [];
    }
  }

  /// Get search suggestions/autocomplete
  static Future<List<String>> getSuggestions(String query) async {
    if (query.isEmpty) return [];

    try {
      final body = {
        'query': query,
        'hitsPerPage': 5,
        'attributesToRetrieve': ['title'],
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/query'),
        headers: {
          'X-Algolia-API-Key': _searchKey,
          'X-Algolia-Application-Id': _appId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = data['hits'] as List;

        return hits
            .map((hit) => hit['title'] as String? ?? '')
            .where((title) => title.isNotEmpty)
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Algolia suggestions error: $e');
      return [];
    }
  }

  /// Search nearby cars using geo-location
  static Future<List<Product>> searchNearby({
    required double latitude,
    required double longitude,
    int radiusInMeters = 50000,
    String query = '',
    int hitsPerPage = 20,
  }) async {
    try {
      final body = {
        'query': query,
        'aroundLatLng': '$latitude,$longitude',
        'aroundRadius': radiusInMeters,
        'hitsPerPage': hitsPerPage,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/query'),
        headers: {
          'X-Algolia-API-Key': _searchKey,
          'X-Algolia-Application-Id': _appId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hits = data['hits'] as List;

        return hits
            .map((hit) => Product.fromMap(
                  hit as Map<String, dynamic>,
                  hit['objectID'] as String,
                ))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Algolia geo-search error: $e');
      return [];
    }
  }

  /// Get facets for a specific attribute
  static Future<Map<String, int>> getFacets(String attribute) async {
    try {
      final body = {
        'query': '',
        'facets': [attribute],
        'hitsPerPage': 0,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/query'),
        headers: {
          'X-Algolia-API-Key': _searchKey,
          'X-Algolia-Application-Id': _appId,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final facets = data['facets'] as Map<String, dynamic>?;

        if (facets != null && facets.containsKey(attribute)) {
          return Map<String, int>.from(facets[attribute] as Map);
        }
      }

      return {};
    } catch (e) {
      debugPrint('Algolia facets error: $e');
      return {};
    }
  }

  /// Get popular searches
  static Future<List<String>> getPopularSearches({int limit = 10}) async {
    // This would typically come from analytics
    // For now, return common car-related searches
    return [
      'Renault',
      'Peugeot',
      'Volkswagen',
      'Toyota',
      'Hyundai',
      'Clio',
      'Symbol',
      '208',
      'Golf',
      'Corolla',
    ].take(limit).toList();
  }

  /// Check if Algolia is properly configured
  static bool isConfigured() {
    return _appId.isNotEmpty && _searchKey.isNotEmpty;
  }
}
