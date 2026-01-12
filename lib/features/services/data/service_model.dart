class Service {
  final int id;
  final String uuid;
  final int vendorId;
  final String? vendorName;
  final int categoryId;
  final String? categoryName;
  final String name;
  final String slug;
  final String description;
  final double price;
  final String? duration;
  final String? thumbnail;
  final List<String> images;
  final String status;
  final double rating;
  final int totalRatings;
  final bool isFeatured;
  final DateTime createdAt;

  Service({
    required this.id,
    required this.uuid,
    required this.vendorId,
    this.vendorName,
    required this.categoryId,
    this.categoryName,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    this.duration,
    this.thumbnail,
    required this.images,
    required this.status,
    required this.rating,
    required this.totalRatings,
    required this.isFeatured,
    required this.createdAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    List<String> imageList = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        imageList = (json['images'] as List).map((e) => e.toString()).toList();
      } else if (json['images'] is String) {
        imageList = [json['images']];
      }
    }

    // Handle thumbnail - check if it's empty string
    String? thumbnailValue = json['thumbnail'];
    if (thumbnailValue != null && thumbnailValue.trim().isEmpty) {
      thumbnailValue = null;
    }
    thumbnailValue = thumbnailValue ?? (imageList.isNotEmpty ? imageList.first : null);

    return Service(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      vendorId: json['vendor_id'] ?? 0,
      vendorName: json['vendor_name'] ?? json['store_name'],
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      duration: json['duration'],
      thumbnail: thumbnailValue,
      images: imageList,
      status: json['status'] ?? 'active',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      totalRatings: json['total_ratings'] ?? 0,
      isFeatured: json['is_featured'] == 1 ||
          json['is_featured'] == true ||
          json['is_featured'] == '1',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
