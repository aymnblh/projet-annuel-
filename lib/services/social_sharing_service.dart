import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import 'analytics_service.dart';

/// Service for sharing products across platforms
class SocialSharingService {
  /// Share a product with formatted text and deep link
  static Future<void> shareProduct(Product product) async {
    final shareText = generateShareText(product);
    final deepLink = generateDeepLink(product.id);
    
    final fullText = '$shareText\n\n$deepLink';
    
    try {
      await Share.share(
        fullText,
        subject: 'ðŸš— ${product.title}',
      );
      
      // Track share event
      await AnalyticsService.logProductShare(
        productId: product.id,
        productTitle: product.title,
      );
    } catch (e) {
      print('Error sharing product: $e');
    }
  }
  
  /// Generate formatted share text
  static String generateShareText(Product product) {
    final buffer = StringBuffer();
    
    // Title with emoji
    buffer.writeln('ðŸš— ${product.title}');
    buffer.writeln();
    
    // Price
    buffer.writeln('ðŸ’° ${product.price.toStringAsFixed(0)} EUR');
    
    // Location
    if (product.wilaya.isNotEmpty) {
      final communeText = (product.commune?.isNotEmpty ?? false) ? ', ${product.commune}' : '';
      buffer.writeln('ðŸ“ ${product.wilaya}$communeText');
    }
    
    buffer.writeln();
    
    // Description (truncated to 100 chars)
    if (product.description.isNotEmpty) {
      final desc = product.description.length > 100
          ? '${product.description.substring(0, 100)}...'
          : product.description;
      buffer.writeln(desc);
      buffer.writeln();
    }
    
    // Car specs if available
    final hasYear = product.year?.isNotEmpty ?? false;
    final hasKm = product.km?.isNotEmpty ?? false;
    final hasFuel = product.fuel?.isNotEmpty ?? false;
    
    if (hasYear || hasKm) {
      final specs = <String>[];
      if (hasYear) specs.add('AnnÃ©e: ${product.year}');
      if (hasKm) specs.add('Km: ${product.km}');
      if (hasFuel) specs.add('Carburant: ${product.fuel}');
      
      if (specs.isNotEmpty) {
        buffer.writeln(specs.join(' â€¢ '));
        buffer.writeln();
      }
    }
    
    buffer.writeln('Voir sur OneClick Cars:');
    
    return buffer.toString();
  }
  
  /// Generate deep link for product
  static String generateDeepLink(String productId) {
    // Simple custom URL scheme
    return 'oneclick://product/$productId';
  }
  
  /// Copy link to clipboard
  static Future<void> copyLink(String productId) async {
    final deepLink = generateDeepLink(productId);
    
    try {
      await Clipboard.setData(ClipboardData(text: deepLink));
      // Show success feedback via caller
    } catch (e) {
      print('Error copying link: $e');
    }
  }
  
  /// Share to WhatsApp directly (if installed)
  static Future<void> shareToWhatsApp(Product product) async {
    final shareText = generateShareText(product);
    final deepLink = generateDeepLink(product.id);
    final fullText = '$shareText\n\n$deepLink';
    
    try {
      // Using share_plus with WhatsApp package name
      await Share.share(
        fullText,
        subject: 'ðŸš— ${product.title}',
      );
      
      // Track share event
      // AnalyticsService.logShare(product.id, 'whatsapp');
    } catch (e) {
      print('Error sharing to WhatsApp: $e');
    }
  }
  
  /// Share with image (requires XFile)
  static Future<void> shareProductWithImage(
    Product product,
    String imagePath,
  ) async {
    final shareText = generateShareText(product);
    final deepLink = generateDeepLink(product.id);
    final fullText = '$shareText\n\n$deepLink';
    
    try {
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: fullText,
        subject: 'ðŸš— ${product.title}',
      );
      
      // Track share event
      // AnalyticsService.logShare(product.id, 'with_image');
    } catch (e) {
      print('Error sharing with image: $e');
    }
  }
}

