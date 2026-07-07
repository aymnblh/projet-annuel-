import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final String category;
  final String wilaya;
  final String? commune;
  final List<String> imageUrls;
  final String? phone;
  final DateTime createdAt;
  final bool isSold;

  // --- LISTING TYPE ---
  /// 'sale' | 'rent' | 'both'
  final String listingType;

  // --- SELLER LOCATION ---
  final String sellerCountry; // defaults to 'Algérie'

  // --- CAR SPECIFIC FIELDS ---
  final String? subCategory;
  final String? brand;
  final String? model;
  final String? year;
  final String? km;
  final String? fuel;
  final String? gearbox;
  final String? engine;
  final String? color;
  final String? papers;
  final bool exchange;
  final String? vehicleType; // Citadine, Berline, SUV, etc.

  // --- AI-DETECTED EQUIPMENT ---
  final List<String> detectedEquipments; // e.g. ['Toit ouvrant', 'Sièges cuir', 'GPS']

  // --- RENTAL SPECIFIC FIELDS ---
  final double? pricePerDay;
  final double? pricePerWeek;
  final double? deposit;         // Caution / dépôt de garantie
  final String? deliveryOption;  // 'Sur place' | 'Livraison' | 'Les deux'
  final int minRentalDays;
  final bool isAvailableForRent;
  final List<DateTime> blockedDates;

  // --- MEDIA ---
  final List<String> videoUrls;

  // --- BOOST ---
  final bool isBoosted;
  final DateTime? boostExpiresAt;
  final bool isUrgent;

  // --- COMMON ---
  final int viewCount;
  final Map<String, dynamic> specs;
  final bool isApproved;

  // --- REVIEWS ---
  final double averageRating;
  final int reviewCount;
  final Map<String, int> ratingDistribution;

  // --- LEAD TRACKING ---
  final int callCount;      // "Appeler" button clicks
  final int whatsappCount;  // "WhatsApp" button clicks

  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.wilaya,
    this.commune,
    required this.imageUrls,
    this.videoUrls = const [],
    this.phone,
    required this.createdAt,
    required this.isSold,
    this.listingType = 'sale',
    this.sellerCountry = 'Algérie',
    this.subCategory,
    this.brand,
    this.model,
    this.year,
    this.km,
    this.fuel,
    this.gearbox,
    this.engine,
    this.color,
    this.papers,
    this.exchange = false,
    this.vehicleType,
    this.detectedEquipments = const [],
    this.pricePerDay,
    this.pricePerWeek,
    this.deposit,
    this.deliveryOption,
    this.minRentalDays = 1,
    this.isAvailableForRent = true,
    this.blockedDates = const [],
    this.isBoosted = false,
    this.boostExpiresAt,
    this.isUrgent = false,
    this.viewCount = 0,
    this.specs = const {},
    this.isApproved = false,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.ratingDistribution = const {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
    this.callCount = 0,
    this.whatsappCount = 0,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    DateTime toDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    List<DateTime> toDateTimeList(dynamic val) {
      if (val == null) return [];
      if (val is List) {
        return val.map((e) => toDateTime(e)).toList();
      }
      return [];
    }

    return Product(
      id: id,
      sellerId: data['sellerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] is int)
          ? (data['price'] as int).toDouble()
          : (data['price'] as double? ?? 0.0),
      category: data['category'] ?? 'Voitures Occasion',
      wilaya: data['wilaya'] ?? '',
      commune: data['commune'],
      imageUrls: (data['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      videoUrls: (data['videoUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      phone: data['phone'],
      createdAt: toDateTime(data['createdAt']),
      isSold: data['isSold'] ?? false,
      listingType: data['listingType'] ?? 'sale',
      sellerCountry: data['sellerCountry'] ?? 'Algérie',
      subCategory: data['subCategory'],
      brand: data['brand'],
      model: data['model'],
      year: data['year'],
      km: data['km'],
      fuel: data['fuel'],
      gearbox: data['gearbox'],
      engine: data['engine'],
      color: data['color'],
      papers: data['papers'],
      exchange: data['exchange'] ?? false,
      vehicleType: data['vehicleType'],
      detectedEquipments: (data['detectedEquipments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      pricePerDay: (data['pricePerDay'] as num?)?.toDouble(),
      pricePerWeek: (data['pricePerWeek'] as num?)?.toDouble(),
      deposit: (data['deposit'] as num?)?.toDouble(),
      deliveryOption: data['deliveryOption'],
      minRentalDays: data['minRentalDays'] ?? 1,
      isAvailableForRent: data['isAvailableForRent'] ?? true,
      blockedDates: toDateTimeList(data['blockedDates']),
      isBoosted: data['isBoosted'] ?? false,
      boostExpiresAt: data['boostExpiresAt'] != null ? toDateTime(data['boostExpiresAt']) : null,
      isUrgent: data['isUrgent'] ?? false,
      viewCount: data['viewCount'] ?? 0,
      specs: data['specs'] ?? {},
      isApproved: data['isApproved'] ?? false,
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      ratingDistribution: Map<String, int>.from(
        data['ratingDistribution'] ?? {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
      ),
      callCount: data['callCount'] ?? 0,
      whatsappCount: data['whatsappCount'] ?? 0,
    );
  }

  /// Factory constructor for data from the self-hosted PostgreSQL API (snake_case keys)
  factory Product.fromApi(Map<String, dynamic> data) {
    DateTime toDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Product(
      id: data['id'] ?? '',
      sellerId: data['seller_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'Voitures Occasion',
      wilaya: data['wilaya'] ?? '',
      commune: data['commune'],
      imageUrls: (data['image_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      videoUrls: (data['video_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      phone: data['phone'],
      createdAt: toDateTime(data['created_at']),
      isSold: data['is_sold'] ?? false,
      listingType: data['listing_type'] ?? 'sale',
      sellerCountry: data['seller_country'] ?? 'Algérie',
      subCategory: data['sub_category'],
      brand: data['brand'],
      model: data['model'],
      year: data['year'],
      km: data['km'],
      fuel: data['fuel'],
      gearbox: data['gearbox'],
      engine: data['engine'],
      color: data['color'],
      papers: data['papers'],
      exchange: data['exchange'] ?? false,
      vehicleType: data['vehicle_type'],
      detectedEquipments: (data['detected_equipments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      pricePerDay: (data['price_per_day'] as num?)?.toDouble(),
      pricePerWeek: (data['price_per_week'] as num?)?.toDouble(),
      deposit: (data['deposit'] as num?)?.toDouble(),
      deliveryOption: data['delivery_option'],
      minRentalDays: data['min_rental_days'] ?? 1,
      isAvailableForRent: data['is_available_for_rent'] ?? true,
      blockedDates: [],
      isBoosted: data['is_boosted'] ?? false,
      isUrgent: data['is_urgent'] ?? false,
      viewCount: data['view_count'] ?? 0,
      specs: Map<String, dynamic>.from(data['specs'] ?? {}),
      isApproved: data['is_approved'] ?? false,
      averageRating: (data['average_rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['review_count'] ?? 0,
      ratingDistribution: {
        '1': (data['rating_distribution']?['1'] as num?)?.toInt() ?? 0,
        '2': (data['rating_distribution']?['2'] as num?)?.toInt() ?? 0,
        '3': (data['rating_distribution']?['3'] as num?)?.toInt() ?? 0,
        '4': (data['rating_distribution']?['4'] as num?)?.toInt() ?? 0,
        '5': (data['rating_distribution']?['5'] as num?)?.toInt() ?? 0,
      },
      callCount: data['call_count'] ?? 0,
      whatsappCount: data['whatsapp_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'wilaya': wilaya,
      'commune': commune,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'phone': phone,
      'createdAt': createdAt,
      'isSold': isSold,
      'listingType': listingType,
      'sellerCountry': sellerCountry,
      'subCategory': subCategory,
      'brand': brand,
      'model': model,
      'year': year,
      'km': km,
      'fuel': fuel,
      'gearbox': gearbox,
      'engine': engine,
      'color': color,
      'papers': papers,
      'exchange': exchange,
      'vehicleType': vehicleType,
      'detectedEquipments': detectedEquipments,
      'pricePerDay': pricePerDay,
      'pricePerWeek': pricePerWeek,
      'deposit': deposit,
      'deliveryOption': deliveryOption,
      'minRentalDays': minRentalDays,
      'isAvailableForRent': isAvailableForRent,
      'blockedDates': blockedDates.map((d) => Timestamp.fromDate(d)).toList(),
      'isBoosted': isBoosted,
      'boostExpiresAt': boostExpiresAt,
      'isUrgent': isUrgent,
      'viewCount': viewCount,
      'specs': specs,
      'isApproved': isApproved,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'ratingDistribution': ratingDistribution,
      'callCount': callCount,
      'whatsappCount': whatsappCount,
    };
  }

  /// True if the car's model year is eligible for import (< 3 years old)
  bool get isImportEligible {
    if (year == null) return false;
    final carYear = int.tryParse(year!);
    if (carYear == null) return false;
    return (DateTime.now().year - carYear) < 3;
  }

  /// True if this listing is from outside Algeria
  bool get isImported => sellerCountry != 'Algérie';
}
