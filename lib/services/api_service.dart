import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/product.dart';
import '../models/review.dart';

/// ApiService: The bridge between the Flutter app and the self-hosted backend.
/// Used for data operations (products, reviews, users).
/// Firebase Auth & Firebase Storage are still used for authentication and media.
class ApiService {
  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  /// Returns the Firebase ID token for authenticated requests.
  static Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─────────────────────────────────────────────
  // PRODUCTS
  // ─────────────────────────────────────────────

  static Future<List<Product>> getProducts({
    String? wilaya,
    String? brand,
    String? fuel,
    String? category,
    double? minPrice,
    double? maxPrice,
    int skip = 0,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
      if (wilaya != null) 'wilaya': wilaya,
      if (brand != null) 'brand': brand,
      if (fuel != null) 'fuel': fuel,
      if (category != null) 'category': category,
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
    };
    final uri = Uri.parse('$_baseUrl/products').replace(queryParameters: params);
    final resp = await http.get(uri, headers: await _authHeaders());
    if (resp.statusCode == 200) {
      final List data = json.decode(resp.body);
      return data.map((e) => Product.fromApi(e)).toList();
    }
    throw Exception('Failed to fetch products: ${resp.statusCode}');
  }

  static Future<List<Product>> searchProducts(String query) async {
    final uri = Uri.parse('$_baseUrl/products/search').replace(
      queryParameters: {'q': query},
    );
    final resp = await http.get(uri, headers: await _authHeaders());
    if (resp.statusCode == 200) {
      final List data = json.decode(resp.body);
      return data.map((e) => Product.fromApi(e)).toList();
    }
    throw Exception('Search failed: ${resp.statusCode}');
  }

  static Future<Product?> getProduct(String productId) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: await _authHeaders(),
    );
    if (resp.statusCode == 200) {
      return Product.fromApi(json.decode(resp.body));
    }
    return null;
  }

  static Future<Product?> createProduct(Map<String, dynamic> data) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/products'),
      headers: await _authHeaders(),
      body: json.encode(data),
    );
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return Product.fromApi(json.decode(resp.body));
    }
    throw Exception('Failed to create product: ${resp.body}');
  }

  static Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
    final resp = await http.put(
      Uri.parse('$_baseUrl/products/$id'),
      headers: await _authHeaders(),
      body: json.encode(data),
    );
    return resp.statusCode == 200;
  }

  static Future<bool> deleteProduct(String productId) async {
    final resp = await http.delete(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: await _authHeaders(),
    );
    return resp.statusCode == 200;
  }

  // ─────────────────────────────────────────────
  // REVIEWS
  // ─────────────────────────────────────────────

  static Future<List<Review>> getProductReviews(String productId) async {
    final resp = await http.get(
      Uri.parse('$_baseUrl/reviews/product/$productId'),
      headers: await _authHeaders(),
    );
    if (resp.statusCode == 200) {
      final List data = json.decode(resp.body);
      return data.map((e) => Review.fromApi(e)).toList();
    }
    return [];
  }

  static Future<bool> submitReview(Map<String, dynamic> data) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/reviews'),
      headers: await _authHeaders(),
      body: json.encode(data),
    );
    return resp.statusCode == 200 || resp.statusCode == 201;
  }

  // ─────────────────────────────────────────────
  // USERS
  // ─────────────────────────────────────────────

  static Future<void> syncUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final token = await user.getIdToken();
    await http.post(
      Uri.parse('$_baseUrl/auth/sync'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}
