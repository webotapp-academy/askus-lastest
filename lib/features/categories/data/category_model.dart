import 'dart:convert';

class Category {
  final int id;
  final String name;
  final String slug;
  final int? parentId;
  final String? icon;
  final String? image;
  final String? description;
  final int sortOrder;
  final String status;
  final int productCount;
  final int serviceCount;
  final List<String> galleryImages;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.icon,
    this.image,
    this.description,
    required this.sortOrder,
    required this.status,
    this.productCount = 0,
    this.serviceCount = 0,
    this.galleryImages = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    int? parentIdValue;
    if (json['parent_id'] != null) {
      final parsed = int.tryParse(json['parent_id'].toString());
      parentIdValue = (parsed == 0) ? null : parsed;
    }

    // Parse gallery images from JSON string
    List<String> galleryImagesList = [];
    try {
      final dynamic galleryData = json['gallery_images'];
      
      if (galleryData != null && galleryData.toString().isNotEmpty) {
        if (galleryData is String) {
          // Parse JSON string
          final decoded = jsonDecode(galleryData);
          if (decoded is List && decoded.isNotEmpty) {
            galleryImagesList = List<String>.from(
              decoded.map((e) => e.toString()).toList()
            );
          }
        } else if (galleryData is List && galleryData.isNotEmpty) {
          // Already a list
          galleryImagesList = List<String>.from(
            galleryData.map((e) => e.toString()).toList()
          );
        }
      }
    } catch (e) {
      print('⚠️ Error parsing gallery images: $e');
      galleryImagesList = []; // Ensure it's always a list
    }

    return Category(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      parentId: parentIdValue,
      icon: json['icon']?.toString(),
      image: json['image']?.toString(),
      description: json['description']?.toString(),
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'active',
      productCount: int.tryParse(json['product_count']?.toString() ?? '0') ?? 0,
      serviceCount: int.tryParse(json['service_count']?.toString() ?? '0') ?? 0,
      galleryImages: galleryImagesList,
    );
  }

  bool get isParent => parentId == null;
}
