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
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    int? parentIdValue;
    if (json['parent_id'] != null) {
      final parsed = int.tryParse(json['parent_id'].toString());
      parentIdValue = (parsed == 0) ? null : parsed;
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
    );
  }

  bool get isParent => parentId == null;
}
