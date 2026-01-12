class User {
  final int id;
  final String uuid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? avatar;
  final String status;
  final VendorProfile? vendorProfile;
  final DateTime createdAt;

  User({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
    required this.status,
    this.vendorProfile,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      avatar: json['avatar']?.toString(),
      status: json['status']?.toString() ?? 'active',
      vendorProfile: json['vendor_profile'] != null
          ? VendorProfile.fromJson(json['vendor_profile'])
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  bool get isVendor => role == 'vendor';
  bool get isUser => role == 'user';
  bool get isApproved => vendorProfile?.status == 'approved';
  bool get isPending => vendorProfile?.status == 'pending';
}

class VendorProfile {
  final int id;
  final String storeName;
  final String? logo;
  final String? banner;
  final String? description;
  final String storeAddress;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String status;
  final double commissionRate;
  final double rating;
  final int totalRatings;
  final bool isVerified;
  final String? gstNumber;
  final String? panNumber;
  final String? fssaiNumber;

  VendorProfile({
    required this.id,
    required this.storeName,
    this.logo,
    this.banner,
    this.description,
    required this.storeAddress,
    required this.city,
    required this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
    required this.status,
    required this.commissionRate,
    required this.rating,
    required this.totalRatings,
    required this.isVerified,
    this.gstNumber,
    this.panNumber,
    this.fssaiNumber,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      storeName: json['store_name']?.toString() ?? '',
      logo: json['logo']?.toString(),
      banner: json['banner']?.toString(),
      description: json['description']?.toString(),
      storeAddress: json['store_address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'pending',
      commissionRate: double.tryParse(json['commission_rate']?.toString() ?? '10') ?? 10,
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      totalRatings: int.tryParse(json['total_ratings']?.toString() ?? '0') ?? 0,
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true || json['is_verified']?.toString() == 'true',
      gstNumber: json['gst_number']?.toString(),
      panNumber: json['pan_number']?.toString(),
      fssaiNumber: json['fssai_number']?.toString(),
    );
  }
}
