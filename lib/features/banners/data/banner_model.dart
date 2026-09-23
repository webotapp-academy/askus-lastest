import '../../../core/utils/helpers.dart';

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
      id: _parseInt(json['id']),
      title: json['title'],
      image: Helpers.fixImageUrl(json['image']?.toString()),
      mobileImage: json['mobile_image'] != null
          ? Helpers.fixImageUrl(json['mobile_image'].toString())
          : null,
      linkType: json['link_type'] ?? 'none',
      linkValue: json['link_value'],
      position: json['position'] ?? 'home_top',
      sortOrder: _parseInt(json['sort_order']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
