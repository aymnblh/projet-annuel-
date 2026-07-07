import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'product_details_screen.dart';
import '../services/analytics_service.dart';
import '../utils/app_translations.dart';
import '../main.dart';

class DeepLinkProductLoader extends StatefulWidget {
  final String productId;
  const DeepLinkProductLoader({super.key, required this.productId});

  @override
  State<DeepLinkProductLoader> createState() => _DeepLinkProductLoaderState();
}

class _DeepLinkProductLoaderState extends State<DeepLinkProductLoader> {
  bool _isLoading = true;
  String? _error;
  Product? _product;

  String t(String key) => AppTranslations.get(languageNotifier.value, key);

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
      if (doc.exists) {
        setState(() {
          _product = Product.fromFirestore(doc);
          _isLoading = false;
        });
        
        // Track successful deep link open
        await AnalyticsService.logDeepLinkOpened(
          productId: widget.productId,
        );
      } else {
        setState(() {
          _error = t('error_product_not_found');
          _isLoading = false;
        });
        
        // Track deep link error
        await AnalyticsService.logDeepLinkError(
          productId: widget.productId,
          errorType: 'product_not_found',
        );
      }
    } catch (e) {
      setState(() {
        _error = "${t('error_loading')}: $e";
        _isLoading = false;
      });
      
      // Track deep link error
      await AnalyticsService.logDeepLinkError(
        productId: widget.productId,
        errorType: 'network_error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(t('deep_link_error_title'))),
        body: Center(child: Text(_error!)),
      );
    }

    if (_product != null) {
      return ProductDetailsScreen(product: _product!);
    }

    return const Scaffold(body: Center(child: Text("Erreur inconnue")));
  }
}
