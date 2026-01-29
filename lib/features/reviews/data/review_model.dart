class Review {
  final int id;
  final int userId;
  final int? orderId;
  final int? productId;
  final int? vendorId;
  final int? deliveryAgentId;
  final String reviewType; // 'product', 'vendor', 'delivery'
  final int rating;
  final String? title;
  final String? comment;
  final List<String> images;
  final bool isVerifiedPurchase;
  final bool isApproved;
  final String? adminReply;
  final DateTime? repliedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from joins
  final String? userName;
  final String? userAvatar;
  final String? productName;
  final String? vendorName;

  Review({
    required this.id,
    required this.userId,
    this.orderId,
    this.productId,
    this.vendorId,
    this.deliveryAgentId,
    required this.reviewType,
    required this.rating,
    this.title,
    this.comment,
    this.images = const [],
    this.isVerifiedPurchase = false,
    this.isApproved = true,
    this.adminReply,
    this.repliedAt,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatar,
    this.productName,
    this.vendorName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    List<String> parseImages(dynamic imagesData) {
      if (imagesData == null) return [];
      if (imagesData is List) {
        return imagesData.map((e) => e.toString()).toList();
      }
      if (imagesData is String && imagesData.isNotEmpty) {
        try {
          return (imagesData as String)
              .split(',')
              .where((s) => s.isNotEmpty)
              .toList();
        } catch (_) {
          return [];
        }
      }
      return [];
    }

    return Review(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      orderId: int.tryParse(json['order_id']?.toString() ?? ''),
      productId: int.tryParse(json['product_id']?.toString() ?? ''),
      vendorId: int.tryParse(json['vendor_id']?.toString() ?? ''),
      deliveryAgentId:
          int.tryParse(json['delivery_agent_id']?.toString() ?? ''),
      reviewType: json['review_type']?.toString() ?? 'product',
      rating: int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString(),
      comment: json['comment']?.toString(),
      images: parseImages(json['images']),
      isVerifiedPurchase: json['is_verified_purchase'] == 1 ||
          json['is_verified_purchase'] == true,
      isApproved: json['is_approved'] == 1 || json['is_approved'] == true,
      adminReply: json['admin_reply']?.toString(),
      repliedAt: DateTime.tryParse(json['replied_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      userName: json['user_name']?.toString(),
      userAvatar: json['user_avatar']?.toString(),
      productName: json['product_name']?.toString(),
      vendorName: json['vendor_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_id': orderId,
      'product_id': productId,
      'vendor_id': vendorId,
      'delivery_agent_id': deliveryAgentId,
      'review_type': reviewType,
      'rating': rating,
      'title': title,
      'comment': comment,
      'images': images,
      'is_verified_purchase': isVerifiedPurchase ? 1 : 0,
      'is_approved': isApproved ? 1 : 0,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    Map<int, int> distribution = {};
    if (json['distribution'] != null) {
      final dist = json['distribution'] as Map<String, dynamic>;
      dist.forEach((key, value) {
        distribution[int.tryParse(key) ?? 0] =
            int.tryParse(value.toString()) ?? 0;
      });
    }

    return ReviewStats(
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0,
      totalReviews: int.tryParse(json['total_reviews']?.toString() ?? '0') ?? 0,
      ratingDistribution: distribution,
    );
  }

  double getPercentage(int rating) {
    if (totalReviews == 0) return 0;
    return ((ratingDistribution[rating] ?? 0) / totalReviews) * 100;
  }
}
