import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String productId;
  final String sellerId;
  final String userId;
  final String userName;
  final String? userPhoto;
  final int rating; // 1-5 stars
  final String comment;
  final List<String> photos;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Moderation
  final bool isApproved; // Admin approval required
  
  // Engagement
  final int helpfulCount;
  final int reportCount;
  
  // Seller Response
  final String? sellerResponse;
  final DateTime? sellerResponseDate;
  
  // Flagging
  final bool isFlagged;
  final String? flagReason;
  final DateTime? flaggedAt;
  
  // Future
  final bool isVerifiedPurchase;

  Review({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.rating,
    required this.comment,
    this.photos = const [],
    required this.createdAt,
    this.updatedAt,
    this.isApproved = false,
    this.helpfulCount = 0,
    this.reportCount = 0,
    this.sellerResponse,
    this.sellerResponseDate,
    this.isFlagged = false,
    this.flagReason,
    this.flaggedAt,
    this.isVerifiedPurchase = false,
  });

  // From Firestore
  factory Review.fromFirestore(Map<String, dynamic> data, String id) {
    return Review(
      id: id,
      productId: data['productId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userPhoto: data['userPhoto'],
      rating: data['rating'] ?? 5,
      comment: data['comment'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isApproved: data['isApproved'] ?? false,
      helpfulCount: data['helpfulCount'] ?? 0,
      reportCount: data['reportCount'] ?? 0,
      sellerResponse: data['sellerResponse'],
      sellerResponseDate: (data['sellerResponseDate'] as Timestamp?)?.toDate(),
      isFlagged: data['isFlagged'] ?? false,
      flagReason: data['flagReason'],
      flaggedAt: (data['flaggedAt'] as Timestamp?)?.toDate(),
      isVerifiedPurchase: data['isVerifiedPurchase'] ?? false,
    );
  }

  /// Factory constructor for data from the self-hosted PostgreSQL API (snake_case keys)
  factory Review.fromApi(Map<String, dynamic> data) {
    return Review(
      id: data['id'] ?? '',
      productId: data['product_id'] ?? '',
      sellerId: data['seller_id'] ?? '',
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? 'Anonymous',
      userPhoto: data['user_photo'],
      rating: data['rating'] ?? 5,
      comment: data['comment'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at']) ?? DateTime.now()
          : DateTime.now(),
      isApproved: data['is_approved'] ?? false,
      helpfulCount: data['helpful_count'] ?? 0,
      reportCount: data['report_count'] ?? 0,
      sellerResponse: data['seller_response'],
      sellerResponseDate: data['seller_response_date'] != null
          ? DateTime.tryParse(data['seller_response_date'])
          : null,
      isFlagged: data['is_flagged'] ?? false,
      flagReason: data['flag_reason'],
      isVerifiedPurchase: data['is_verified_purchase'] ?? false,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'sellerId': sellerId,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'rating': rating,
      'comment': comment,
      'photos': photos,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isApproved': isApproved,
      'helpfulCount': helpfulCount,
      'reportCount': reportCount,
      'sellerResponse': sellerResponse,
      'sellerResponseDate': sellerResponseDate != null 
          ? Timestamp.fromDate(sellerResponseDate!) 
          : null,
      'isFlagged': isFlagged,
      'flagReason': flagReason,
      'flaggedAt': flaggedAt != null ? Timestamp.fromDate(flaggedAt!) : null,
      'isVerifiedPurchase': isVerifiedPurchase,
    };
  }

  // Copy with
  Review copyWith({
    String? id,
    String? productId,
    String? sellerId,
    String? userId,
    String? userName,
    String? userPhoto,
    int? rating,
    String? comment,
    List<String>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isApproved,
    int? helpfulCount,
    int? reportCount,
    String? sellerResponse,
    DateTime? sellerResponseDate,
    bool? isFlagged,
    String? flagReason,
    DateTime? flaggedAt,
    bool? isVerifiedPurchase,
  }) {
    return Review(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      sellerId: sellerId ?? this.sellerId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhoto: userPhoto ?? this.userPhoto,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isApproved: isApproved ?? this.isApproved,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      reportCount: reportCount ?? this.reportCount,
      sellerResponse: sellerResponse ?? this.sellerResponse,
      sellerResponseDate: sellerResponseDate ?? this.sellerResponseDate,
      isFlagged: isFlagged ?? this.isFlagged,
      flagReason: flagReason ?? this.flagReason,
      flaggedAt: flaggedAt ?? this.flaggedAt,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
    );
  }
}

