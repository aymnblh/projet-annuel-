import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for tracking user behavior and building interest profiles.
///
/// Stores behavior events in `users/{uid}/behaviorLog` and computes
/// an aggregated interest profile in `users/{uid}/interestProfile`.
class BehaviorTrackingService {
  // ── Singleton ──
  BehaviorTrackingService._internal();
  static final BehaviorTrackingService _instance =
      BehaviorTrackingService._internal();
  factory BehaviorTrackingService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Minimum interactions before an interest profile is generated.
  static const int _minInteractions = 5;

  // ────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _behaviorLog {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('behaviorLog');
  }

  DocumentReference? get _interestProfileDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('interestProfile').doc('current');
  }

  // ────────────────────────────────────────────
  // Tracking Methods
  // ────────────────────────────────────────────

  /// Called when the user opens a product detail page.
  Future<void> trackProductView(
    String productId,
    String brand,
    String category,
    double price,
    String? fuel,
    String? vehicleType,
  ) async {
    try {
      final log = _behaviorLog;
      if (log == null) return;

      await log.add({
        'type': 'view',
        'productId': productId,
        'brand': brand,
        'category': category,
        'price': price,
        'fuel': fuel,
        'vehicleType': vehicleType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('[BehaviorTracking] Tracked view: $productId');
    } catch (e) {
      debugPrint('[BehaviorTracking] Error tracking view: $e');
    }
  }

  /// Called when the user leaves the product detail page.
  Future<void> trackViewDuration(String productId, int durationSeconds) async {
    try {
      final log = _behaviorLog;
      if (log == null) return;

      await log.add({
        'type': 'viewDuration',
        'productId': productId,
        'durationSeconds': durationSeconds,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint(
          '[BehaviorTracking] Tracked duration: ${durationSeconds}s for $productId');
    } catch (e) {
      debugPrint('[BehaviorTracking] Error tracking duration: $e');
    }
  }

  /// Tracks how many photos the user swiped through.
  Future<void> trackPhotoSwipe(String productId, int photoCount) async {
    try {
      final log = _behaviorLog;
      if (log == null) return;

      await log.add({
        'type': 'photoSwipe',
        'productId': productId,
        'photoCount': photoCount,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint(
          '[BehaviorTracking] Tracked photo swipe: $photoCount photos for $productId');
    } catch (e) {
      debugPrint('[BehaviorTracking] Error tracking photo swipe: $e');
    }
  }

  /// Called when the user favorites a product.
  Future<void> trackFavorite(
    String productId,
    String brand,
    String category,
    double price,
  ) async {
    try {
      final log = _behaviorLog;
      if (log == null) return;

      await log.add({
        'type': 'favorite',
        'productId': productId,
        'brand': brand,
        'category': category,
        'price': price,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('[BehaviorTracking] Tracked favorite: $productId');
    } catch (e) {
      debugPrint('[BehaviorTracking] Error tracking favorite: $e');
    }
  }

  /// Called when the user contacts a seller (call / whatsapp / chat).
  Future<void> trackContact(
    String productId,
    String brand,
    String contactType,
  ) async {
    try {
      final log = _behaviorLog;
      if (log == null) return;

      await log.add({
        'type': 'contact',
        'productId': productId,
        'brand': brand,
        'contactType': contactType, // 'call' | 'whatsapp' | 'chat'
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint(
          '[BehaviorTracking] Tracked contact ($contactType): $productId');
    } catch (e) {
      debugPrint('[BehaviorTracking] Error tracking contact: $e');
    }
  }

  // ────────────────────────────────────────────
  // Interest Profile
  // ────────────────────────────────────────────

  /// Analyses the user's behaviorLog and computes an interest profile.
  ///
  /// The profile contains:
  /// - `topBrands`        : Top 3 brands by interaction frequency
  /// - `priceRange`       : `{ min, max }` average price corridor
  /// - `preferredFuels`   : List of preferred fuel types
  /// - `preferredVehicleTypes` : List of preferred vehicle types
  /// - `engagementScores` : Map of category → weighted engagement score
  /// - `totalInteractions`: Total number of behaviour events used
  /// - `updatedAt`        : Server timestamp
  Future<void> updateInterestProfile() async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final logRef = _behaviorLog;
      final profileDoc = _interestProfileDoc;
      if (logRef == null || profileDoc == null) return;

      // Fetch all behaviour events
      final snapshot = await logRef
          .orderBy('timestamp', descending: true)
          .limit(500)
          .get();

      if (snapshot.docs.length < _minInteractions) {
        debugPrint(
            '[BehaviorTracking] Not enough interactions (${snapshot.docs.length}/$_minInteractions)');
        return;
      }

      // ── Aggregate data ──
      final brandCount = <String, int>{};
      final fuelCount = <String, int>{};
      final vehicleTypeCount = <String, int>{};
      final categoryEngagement = <String, double>{};
      final prices = <double>[];

      // Weights per event type
      const weights = <String, double>{
        'view': 1.0,
        'viewDuration': 0.5,
        'photoSwipe': 1.5,
        'favorite': 3.0,
        'contact': 5.0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final type = data['type'] as String? ?? '';
        final weight = weights[type] ?? 1.0;

        // Brand
        final brand = data['brand'] as String?;
        if (brand != null && brand.isNotEmpty) {
          brandCount[brand] = (brandCount[brand] ?? 0) + weight.round();
        }

        // Fuel
        final fuel = data['fuel'] as String?;
        if (fuel != null && fuel.isNotEmpty) {
          fuelCount[fuel] = (fuelCount[fuel] ?? 0) + 1;
        }

        // Vehicle type
        final vType = data['vehicleType'] as String?;
        if (vType != null && vType.isNotEmpty) {
          vehicleTypeCount[vType] = (vehicleTypeCount[vType] ?? 0) + 1;
        }

        // Category engagement (weighted)
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categoryEngagement[category] =
              (categoryEngagement[category] ?? 0.0) + weight;
        }

        // Price
        final price = (data['price'] as num?)?.toDouble();
        if (price != null && price > 0) {
          prices.add(price);
        }
      }

      // ── Compute profile fields ──

      // Top 3 brands
      final sortedBrands = brandCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topBrands =
          sortedBrands.take(3).map((e) => e.key).toList();

      // Price range
      double minPrice = 0;
      double maxPrice = 0;
      if (prices.isNotEmpty) {
        prices.sort();
        // Use 10th and 90th percentile for a robust range
        final p10Index = (prices.length * 0.1).floor();
        final p90Index = (prices.length * 0.9).ceil().clamp(0, prices.length - 1);
        minPrice = prices[p10Index];
        maxPrice = prices[p90Index];
      }

      // Preferred fuels (those appearing in ≥ 15 % of fuel-tagged events)
      final totalFuelEvents = fuelCount.values.fold<int>(0, (a, b) => a + b);
      final preferredFuels = fuelCount.entries
          .where((e) => totalFuelEvents > 0 && e.value / totalFuelEvents >= 0.15)
          .map((e) => e.key)
          .toList();

      // Preferred vehicle types (same threshold)
      final totalVTypeEvents =
          vehicleTypeCount.values.fold<int>(0, (a, b) => a + b);
      final preferredVehicleTypes = vehicleTypeCount.entries
          .where(
              (e) => totalVTypeEvents > 0 && e.value / totalVTypeEvents >= 0.15)
          .map((e) => e.key)
          .toList();

      // ── Write profile with batch ──
      final batch = _firestore.batch();

      batch.set(profileDoc, {
        'topBrands': topBrands,
        'priceRange': {
          'min': minPrice,
          'max': maxPrice,
        },
        'preferredFuels': preferredFuels,
        'preferredVehicleTypes': preferredVehicleTypes,
        'engagementScores': categoryEngagement,
        'totalInteractions': snapshot.docs.length,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));

      await batch.commit();

      debugPrint(
          '[BehaviorTracking] Interest profile updated – '
          'brands=$topBrands, priceRange=$minPrice-$maxPrice, '
          'fuels=$preferredFuels, vehicleTypes=$preferredVehicleTypes');
    } catch (e) {
      debugPrint('[BehaviorTracking] Error updating interest profile: $e');
    }
  }

  /// Returns the current interest profile, or `null` if there is not
  /// enough data to generate one.
  Future<Map<String, dynamic>?> getInterestProfile() async {
    try {
      final profileDoc = _interestProfileDoc;
      if (profileDoc == null) return null;

      final snapshot = await profileDoc.get();
      if (!snapshot.exists) {
        // Try generating it on the fly
        await updateInterestProfile();
        final retry = await profileDoc.get();
        if (!retry.exists) return null;
        return retry.data() as Map<String, dynamic>?;
      }

      return snapshot.data() as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[BehaviorTracking] Error getting interest profile: $e');
      return null;
    }
  }
}
