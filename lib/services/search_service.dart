import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/product.dart';

class SearchService {
  static String? _appId;
  static String? _apiKey;
  static const int maxRetries = 2;
  static const Duration timeout = Duration(seconds: 10);

  static void init() {
    _appId = dotenv.env['ALGOLIA_APP_ID'];
    _apiKey = dotenv.env['ALGOLIA_API_KEY'];
  }

  /// Search products with error handling and retry logic
  /// 
  /// Returns SearchResult with products and error information
  static Future<SearchResult> searchProducts(
    String query, {
    int retryCount = 0,
  }) async {
    // Lazy init
    if (_appId == null) init();

    if (_appId == null || _apiKey == null || _appId!.isEmpty || _apiKey!.isEmpty) {
      print("[SearchService] Keys missing. Make sure .env has ALGOLIA_APP_ID and ALGOLIA_API_KEY");
      return SearchResult(
        products: [],
        error: SearchError(
          message: 'Service de recherche non configuré. Veuillez réessayer plus tard.',
          type: SearchErrorType.configurationError,
          isRetryable: false,
        ),
      );
    }

    try {
      final url = Uri.parse('https://$_appId-dsn.algolia.net/1/indexes/products/query');
      
      final response = await http.post(
        url,
        headers: {
          'X-Algolia-API-Key': _apiKey!,
          'X-Algolia-Application-Id': _appId!,
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          'params': 'query=$query&hitsPerPage=20'
        }),
      ).timeout(
        timeout,
        onTimeout: () {
          throw SearchTimeoutException('La recherche a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> hits = body['hits'] ?? [];
        
        final products = hits.map((hit) {
          final String objectID = hit['objectID'] ?? '';
          return Product.fromMap(hit as Map<String, dynamic>, objectID);
        }).toList();

        return SearchResult(products: products);
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount + 1));
          return searchProducts(query, retryCount: retryCount + 1);
        }
        
        return SearchResult(
          products: [],
          error: SearchError(
            message: 'Trop de recherches. Veuillez patienter un instant.',
            type: SearchErrorType.rateLimitExceeded,
            isRetryable: true,
          ),
        );
      } else if (response.statusCode >= 500) {
        // Server error - retryable
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount + 1));
          return searchProducts(query, retryCount: retryCount + 1);
        }
        
        return SearchResult(
          products: [],
          error: SearchError(
            message: 'Le service de recherche est temporairement indisponible.',
            type: SearchErrorType.serverError,
            isRetryable: true,
          ),
        );
      } else {
        print("[SearchService] Error ${response.statusCode}: ${response.body}");
        return SearchResult(
          products: [],
          error: SearchError(
            message: 'Une erreur est survenue lors de la recherche.',
            type: SearchErrorType.unknown,
            isRetryable: false,
          ),
        );
      }
    } on SearchTimeoutException catch (e) {
      print("[SearchService] Timeout: $e");
      
      if (retryCount < maxRetries) {
        return searchProducts(query, retryCount: retryCount + 1);
      }
      
      return SearchResult(
        products: [],
        error: SearchError(
          message: 'La recherche a pris trop de temps. Vérifiez votre connexion.',
          type: SearchErrorType.timeout,
          isRetryable: true,
        ),
      );
    } catch (e) {
      print("[SearchService] Exception: $e");
      
      // Network error - retryable
      if (e.toString().contains('SocketException') || 
          e.toString().contains('NetworkException')) {
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(seconds: retryCount + 1));
          return searchProducts(query, retryCount: retryCount + 1);
        }
        
        return SearchResult(
          products: [],
          error: SearchError(
            message: 'Pas de connexion Internet. Vérifiez votre réseau.',
            type: SearchErrorType.networkError,
            isRetryable: true,
          ),
        );
      }
      
      return SearchResult(
        products: [],
        error: SearchError(
          message: 'Une erreur est survenue. Veuillez réessayer.',
          type: SearchErrorType.unknown,
          isRetryable: true,
        ),
      );
    }
  }
}

/// Search result with products and optional error
class SearchResult {
  final List<Product> products;
  final SearchError? error;

  SearchResult({
    required this.products,
    this.error,
  });

  bool get hasError => error != null;
  bool get isSuccess => error == null;
}

/// Search error information
class SearchError {
  final String message;
  final SearchErrorType type;
  final bool isRetryable;

  SearchError({
    required this.message,
    required this.type,
    required this.isRetryable,
  });
}

/// Types of search errors
enum SearchErrorType {
  configurationError,
  networkError,
  timeout,
  rateLimitExceeded,
  serverError,
  unknown,
}

/// Custom exception for search timeouts
class SearchTimeoutException implements Exception {
  final String message;
  SearchTimeoutException(this.message);
  
  @override
  String toString() => message;
}
