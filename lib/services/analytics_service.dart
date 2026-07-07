import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/product.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Log Search Event
  static Future<void> logSearch(String query) async {
    await _analytics.logSearch(searchTerm: query);
  }

  // Log View Item
  static Future<void> logViewItem(Product product) async {
    await _analytics.logViewItem(
      currency: 'DZD',
      value: product.price,
      items: [
        AnalyticsEventItem(
          itemId: product.id,
          itemName: product.title,
          itemCategory: product.category,
          price: product.price,
        ),
      ],
    );
  }

  // Log Add to Cart (Used for Drafts here, or generic interest)
  static Future<void> logAddToCart(Product product) async {
    await _analytics.logAddToCart(
      currency: 'DZD',
      value: product.price,
      items: [
        AnalyticsEventItem(
          itemId: product.id,
          itemName: product.title,
          itemCategory: product.category,
        ),
      ],
    );
  }

  // Custom Event: Phone Call
  static Future<void> logPhoneClick(String productId) async {
    await _analytics.logEvent(
      name: 'click_phone',
      parameters: {'product_id': productId},
    );
  }

  // --- NEW: Recently Viewed Analytics ---
  
  /// Track when a product is viewed (for recently viewed feature)
  static Future<void> logProductView({
    required String productId,
    required String productTitle,
    required String category,
    String? source, // e.g., 'home', 'search', 'similar_products'
  }) async {
    await _analytics.logEvent(
      name: 'product_view',
      parameters: {
        'product_id': productId,
        'product_title': productTitle,
        'category': category,
        if (source != null) 'source': source,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Track when user clicks on a recently viewed product
  static Future<void> logRecentlyViewedClick({
    required String productId,
    required int position, // Position in the list
  }) async {
    await _analytics.logEvent(
      name: 'recently_viewed_click',
      parameters: {
        'product_id': productId,
        'position': position,
      },
    );
  }

  /// Track when user clears recently viewed history
  static Future<void> logRecentlyViewedCleared() async {
    await _analytics.logEvent(name: 'recently_viewed_cleared');
  }

  // --- NEW: Similar Products Analytics ---
  
  /// Track when similar products are shown
  static Future<void> logSimilarProductsShown({
    required String sourceProductId,
    required int count,
    String? matchType, // e.g., 'brand_model', 'category', 'brand'
  }) async {
    await _analytics.logEvent(
      name: 'similar_products_shown',
      parameters: {
        'source_product_id': sourceProductId,
        'count': count,
        if (matchType != null) 'match_type': matchType,
      },
    );
  }

  /// Track when user clicks on a similar product
  static Future<void> logSimilarProductClick({
    required String sourceProductId,
    required String clickedProductId,
    required int position,
  }) async {
    await _analytics.logEvent(
      name: 'similar_product_click',
      parameters: {
        'source_product_id': sourceProductId,
        'clicked_product_id': clickedProductId,
        'position': position,
      },
    );
  }

  // --- NEW: Video Compression Analytics ---
  
  /// Track video compression start
  static Future<void> logVideoCompressionStarted({
    required double originalSizeMB,
  }) async {
    await _analytics.logEvent(
      name: 'video_compression_started',
      parameters: {
        'original_size_mb': originalSizeMB,
      },
    );
  }

  /// Track successful video compression
  static Future<void> logVideoCompressionSuccess({
    required double originalSizeMB,
    required double compressedSizeMB,
    required double reductionPercentage,
    required int durationSeconds,
  }) async {
    await _analytics.logEvent(
      name: 'video_compression_success',
      parameters: {
        'original_size_mb': originalSizeMB,
        'compressed_size_mb': compressedSizeMB,
        'reduction_percentage': reductionPercentage,
        'duration_seconds': durationSeconds,
      },
    );
  }

  /// Track video compression cancellation
  static Future<void> logVideoCompressionCancelled({
    required double progress, // 0.0 to 1.0
  }) async {
    await _analytics.logEvent(
      name: 'video_compression_cancelled',
      parameters: {
        'progress': progress,
      },
    );
  }

  /// Track video compression error
  static Future<void> logVideoCompressionError({
    required String errorType,
    required String errorMessage,
  }) async {
    await _analytics.logEvent(
      name: 'video_compression_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
      },
    );
  }

  // --- NEW: Search Analytics ---
  
  /// Track search with results count
  static Future<void> logSearchWithResults({
    required String query,
    required int resultCount,
    Map<String, dynamic>? filters,
  }) async {
    await _analytics.logEvent(
      name: 'search_with_results',
      parameters: {
        'query': query,
        'result_count': resultCount,
        if (filters != null) ...filters,
      },
    );
  }

  /// Track search autocomplete suggestion click
  static Future<void> logSearchSuggestionClick({
    required String query,
    required String suggestion,
    required String suggestionType, // 'recent', 'popular', 'product'
  }) async {
    await _analytics.logEvent(
      name: 'search_suggestion_click',
      parameters: {
        'query': query,
        'suggestion': suggestion,
        'suggestion_type': suggestionType,
      },
    );
  }

  // --- NEW: Share Analytics ---
  
  /// Track product share
  static Future<void> logProductShare({
    required String productId,
    required String productTitle,
    String? shareMethod, // e.g., 'whatsapp', 'facebook', 'copy_link'
  }) async {
    await _analytics.logEvent(
      name: 'share',
      parameters: {
        'content_type': 'product',
        'item_id': productId,
        'product_title': productTitle,
        if (shareMethod != null) 'method': shareMethod,
      },
    );
  }

  // --- NEW: Deep Linking Analytics ---
  
  /// Track deep link opened
  static Future<void> logDeepLinkOpened({
    required String productId,
    String? source, // e.g., 'notification', 'sms', 'external'
  }) async {
    await _analytics.logEvent(
      name: 'deep_link_opened',
      parameters: {
        'product_id': productId,
        if (source != null) 'source': source,
      },
    );
  }

  /// Track deep link error
  static Future<void> logDeepLinkError({
    required String productId,
    required String errorType, // e.g., 'product_not_found', 'network_error'
  }) async {
    await _analytics.logEvent(
      name: 'deep_link_error',
      parameters: {
        'product_id': productId,
        'error_type': errorType,
      },
    );
  }

  // --- NEW: Error Tracking ---
  
  /// Track general errors for monitoring
  static Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? context, // Where the error occurred
    Map<String, dynamic>? additionalData,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        if (context != null) 'context': context,
        if (additionalData != null) ...additionalData,
      },
    );
  }

  // --- User Engagement ---
  
  /// Track feature usage
  static Future<void> logFeatureUsage({
    required String featureName,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: 'feature_used',
      parameters: {
        'feature_name': featureName,
        if (parameters != null) ...parameters,
      },
    );
  }
}
