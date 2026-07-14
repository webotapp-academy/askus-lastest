class Service {
  final int id;
  final String uuid;
  final int vendorId;
  final String? vendorName;
  final int categoryId;
  final String? categoryName;
  final int? subcategoryId;
  final String? subcategoryName;
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
    this.subcategoryId,
    this.subcategoryName,
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

    // Handle price - try multiple field names
    double priceValue = 0;
    if (json['price'] != null && json['price'].toString().isNotEmpty) {
      priceValue = double.tryParse(json['price'].toString()) ?? 0;
    } else if (json['min_price'] != null && json['min_price'].toString().isNotEmpty) {
      priceValue = double.tryParse(json['min_price'].toString()) ?? 0;
    } else if (json['selling_price'] != null && json['selling_price'].toString().isNotEmpty) {
      priceValue = double.tryParse(json['selling_price'].toString()) ?? 0;
    }

    return Service(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      vendorId: json['vendor_id'] ?? 0,
      vendorName: json['vendor_name'] ?? json['store_name'],
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'],
      subcategoryId: json['subcategory_id'] != null ? int.tryParse(json['subcategory_id'].toString()) : null,
      subcategoryName: json['subcategory_name'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      price: priceValue,
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
