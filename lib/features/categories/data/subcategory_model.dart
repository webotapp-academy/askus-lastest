class Subcategory {
  final int id;
  final int categoryId;
  final String name;
  final String slug;
  final String? description;
  final String? image;
  final int sortOrder;
  final String status;
  final String? categoryName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.slug,
    this.description,
    this.image,
    required this.sortOrder,
    required this.status,
    this.categoryName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: int.tryParse(json['id'].toString()) ?? 0,
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'active',
      categoryName: json['category_name']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'slug': slug,
      'description': description,
      'image': image,
      'sort_order': sortOrder,
      'status': status,
      'category_name': categoryName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
