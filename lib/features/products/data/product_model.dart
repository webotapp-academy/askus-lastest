class Product {
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
  final String? shortDescription;
  final double price;
  final double? comparePrice;
  final int stock;
  final String? sku;
  final String? unit;
  final String? thumbnail;
  final List<String> images;
  final String status;
  final double rating;
  final int totalRatings;
  final int viewCount;
  final bool isFeatured;
  final DateTime createdAt;

  Product({
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
    this.shortDescription,
    required this.price,
    this.comparePrice,
    required this.stock,
    this.sku,
    this.unit,
    this.thumbnail,
    required this.images,
    required this.status,
    required this.rating,
    required this.totalRatings,
    required this.viewCount,
    required this.isFeatured,
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> imageList = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        for (var item in json['images']) {
          if (item is Map) {
            final url = item['image_url'] ?? item['url'] ?? item['image'] ?? item['path'];
            if (url != null && url.toString().trim().isNotEmpty) {
              imageList.add(url.toString().trim());
            }
          } else if (item != null && item.toString().trim().isNotEmpty) {
            imageList.add(item.toString().trim());
          }
        }
      } else if (json['images'] is String && json['images'].toString().trim().isNotEmpty) {
        imageList = [json['images'].toString().trim()];
      }
    }

    // Handle price - try multiple field names
    double priceValue = 0;
    if (json['price'] != null && json['price'].toString().isNotEmpty) {
      priceValue = double.tryParse(json['price'].toString()) ?? 0;
    } else if (json['selling_price'] != null && json['selling_price'].toString().isNotEmpty) {
      priceValue = double.tryParse(json['selling_price'].toString()) ?? 0;
    } else if (json['min_price'] != null && json['min_price'].toString().isNotEmpty) {
      priceValue = double.tryParse(json['min_price'].toString()) ?? 0;
    }

    // Handle compare price - try multiple field names
    double? comparePriceValue;
    if (json['compare_price'] != null && json['compare_price'].toString().isNotEmpty) {
      comparePriceValue = double.tryParse(json['compare_price'].toString());
    } else if (json['mrp'] != null && json['mrp'].toString().isNotEmpty) {
      comparePriceValue = double.tryParse(json['mrp'].toString());
    }

    int stockValue = 0;
    if (json['stock_quantity'] != null) {
      stockValue = int.tryParse(json['stock_quantity']?.toString() ?? '0') ?? 0;
    } else if (json['stock'] != null) {
      stockValue = int.tryParse(json['stock']?.toString() ?? '0') ?? 0;
    }

    // Handle thumbnail - check if it's empty string
    String? thumbnailValue = json['thumbnail'];
    if (thumbnailValue != null && thumbnailValue.trim().isEmpty) {
      thumbnailValue = null;
    }
    thumbnailValue = thumbnailValue ?? (imageList.isNotEmpty ? imageList.first : null);

    // Ensure imageList has at least the thumbnail if available
    if (imageList.isEmpty && thumbnailValue != null && thumbnailValue.isNotEmpty) {
      imageList.add(thumbnailValue);
    }

    return Product(
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
      shortDescription: json['short_description'],
      price: priceValue,
      comparePrice: comparePriceValue,
      stock: stockValue,
      sku: json['sku'],
      unit: json['unit'],
      thumbnail: thumbnailValue,
      images: imageList,
      status: json['status'] ?? 'active',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      totalRatings: json['total_ratings'] ?? json['total_reviews'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get hasDiscount => comparePrice != null && comparePrice! > price;
  double get discountPercent => hasDiscount ? ((comparePrice! - price) / comparePrice! * 100) : 0;
  bool get inStock => stock > 0;
}
