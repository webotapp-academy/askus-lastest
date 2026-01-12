class Vendor {
  final int id;
  final String uuid;
  final String ownerName;
  final String email;
  final String phone;
  final String storeName;
  final String storeSlug;
  final String? storeLogo;
  final String? storeBanner;
  final String? storeDescription;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String? gstNumber;
  final String? panNumber;
  final String? fssaiNumber;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankAccountHolder;
  final String? upiId;
  final double commissionRate;
  final double minOrderAmount;
  final double deliveryRadiusKm;
  final int avgDeliveryTime;
  final double rating;
  final int totalReviews;
  final int totalOrders;
  final bool isFeatured;
  final bool isVerified;
  final bool autoAcceptOrders;
  final bool isOpen;
  final String? openingTime;
  final String? closingTime;
  final String status;
  final DateTime? approvedAt;
  final DateTime createdAt;

  Vendor({
    required this.id,
    required this.uuid,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.storeName,
    required this.storeSlug,
    this.storeLogo,
    this.storeBanner,
    this.storeDescription,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    this.gstNumber,
    this.panNumber,
    this.fssaiNumber,
    this.bankName,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankAccountHolder,
    this.upiId,
    this.commissionRate = 10.0,
    this.minOrderAmount = 0.0,
    this.deliveryRadiusKm = 5.0,
    this.avgDeliveryTime = 30,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalOrders = 0,
    this.isFeatured = false,
    this.isVerified = false,
    this.autoAcceptOrders = false,
    this.isOpen = true,
    this.openingTime,
    this.closingTime,
    required this.status,
    this.approvedAt,
    required this.createdAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      uuid: json['uuid']?.toString() ?? '',
      ownerName:
          json['owner_name']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      storeName: json['store_name']?.toString() ?? '',
      storeSlug: json['store_slug']?.toString() ?? '',
      storeLogo: json['store_logo']?.toString(),
      storeBanner: json['store_banner']?.toString(),
      storeDescription: json['store_description']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      gstNumber: json['gst_number']?.toString(),
      panNumber: json['pan_number']?.toString(),
      fssaiNumber: json['fssai_number']?.toString(),
      bankName: json['bank_name']?.toString(),
      bankAccountNumber: json['bank_account_number']?.toString(),
      bankIfsc: json['bank_ifsc']?.toString(),
      bankAccountHolder: json['bank_account_holder']?.toString(),
      upiId: json['upi_id']?.toString(),
      commissionRate:
          double.tryParse(json['commission_rate']?.toString() ?? '10') ?? 10.0,
      minOrderAmount:
          double.tryParse(json['min_order_amount']?.toString() ?? '0') ?? 0.0,
      deliveryRadiusKm:
          double.tryParse(json['delivery_radius_km']?.toString() ?? '5') ?? 5.0,
      avgDeliveryTime:
          int.tryParse(json['avg_delivery_time']?.toString() ?? '30') ?? 30,
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      totalReviews: int.tryParse(json['total_reviews']?.toString() ?? '0') ?? 0,
      totalOrders: int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == true,
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      autoAcceptOrders:
          json['auto_accept_orders'] == 1 || json['auto_accept_orders'] == true,
      isOpen: json['is_open'] == 1 ||
          json['is_open'] == true ||
          json['is_open'] == null,
      openingTime: json['opening_time']?.toString(),
      closingTime: json['closing_time']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      approvedAt: DateTime.tryParse(json['approved_at']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'owner_name': ownerName,
      'email': email,
      'phone': phone,
      'store_name': storeName,
      'store_slug': storeSlug,
      'store_logo': storeLogo,
      'store_banner': storeBanner,
      'store_description': storeDescription,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'gst_number': gstNumber,
      'pan_number': panNumber,
    };
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isSuspended => status == 'suspended';
}

class VendorStats {
  final int totalProducts;
  final int totalServices;
  final int totalEnquiries;
  final int pendingEnquiries;
  final double totalEarnings;
  final double thisMonthEarnings;
  final int totalOrders;
  final int pendingOrders;
  final double rating;
  final int totalReviews;

  VendorStats({
    this.totalProducts = 0,
    this.totalServices = 0,
    this.totalEnquiries = 0,
    this.pendingEnquiries = 0,
    this.totalEarnings = 0.0,
    this.thisMonthEarnings = 0.0,
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.rating = 0.0,
    this.totalReviews = 0,
  });

  factory VendorStats.fromJson(Map<String, dynamic> json) {
    return VendorStats(
      totalProducts:
          int.tryParse(json['total_products']?.toString() ?? '0') ?? 0,
      totalServices:
          int.tryParse(json['total_services']?.toString() ?? '0') ?? 0,
      totalEnquiries:
          int.tryParse(json['total_enquiries']?.toString() ?? '0') ?? 0,
      pendingEnquiries:
          int.tryParse(json['pending_enquiries']?.toString() ?? '0') ?? 0,
      totalEarnings:
          double.tryParse(json['total_earnings']?.toString() ?? '0') ?? 0.0,
      thisMonthEarnings:
          double.tryParse(json['this_month_earnings']?.toString() ?? '0') ??
              0.0,
      totalOrders: int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,
      pendingOrders:
          int.tryParse(json['pending_orders']?.toString() ?? '0') ?? 0,
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      totalReviews: int.tryParse(json['total_reviews']?.toString() ?? '0') ?? 0,
    );
  }
}

class VendorDocument {
  final int id;
  final int vendorId;
  final String documentType;
  final String? documentNumber;
  final String documentUrl;
  final String status;
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final int? verifiedBy;
  final DateTime createdAt;

  VendorDocument({
    required this.id,
    required this.vendorId,
    required this.documentType,
    this.documentNumber,
    required this.documentUrl,
    required this.status,
    this.rejectionReason,
    this.verifiedAt,
    this.verifiedBy,
    required this.createdAt,
  });

  factory VendorDocument.fromJson(Map<String, dynamic> json) {
    return VendorDocument(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      vendorId: int.tryParse(json['vendor_id']?.toString() ?? '0') ?? 0,
      documentType: json['document_type']?.toString() ?? '',
      documentNumber: json['document_number']?.toString(),
      documentUrl: json['document_url']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      rejectionReason: json['rejection_reason']?.toString(),
      verifiedAt: DateTime.tryParse(json['verified_at']?.toString() ?? ''),
      verifiedBy: int.tryParse(json['verified_by']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
