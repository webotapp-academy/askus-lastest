class Banner {
  final int id;
  final String? title;
  final String image;
  final String? mobileImage;
  final String linkType;
  final String? linkValue;
  final String position;
  final int sortOrder;

  Banner({
    required this.id,
    this.title,
    required this.image,
    this.mobileImage,
    required this.linkType,
    this.linkValue,
    required this.position,
    required this.sortOrder,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id'] ?? 0,
      title: json['title'],
      image: json['image'] ?? '',
      mobileImage: json['mobile_image'],
      linkType: json['link_type'] ?? 'none',
      linkValue: json['link_value'],
      position: json['position'] ?? 'home_top',
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}
