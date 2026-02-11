class ApiConstants {
  static const String baseUrl = 'https://indiawebdesigns.in/app/askus/api';

  // Auth endpoints
  static const String login = '/auth/login.php';
  static const String register = '/auth/register.php';
  static const String profile = '/auth/profile.php';
  static const String updateProfile = '/auth/update-profile.php';
  static const String vendorRegister = '/auth/vendor-register.php';
  static const String vendorKyc = '/auth/vendor-kyc.php';
  static const String vendorLogin = '/auth/vendor-login.php';

  // Vendor specific endpoints
  static const String vendorProfile = '/vendor/profile.php';
  static const String vendorUpdateProfile = '/vendor/update-profile.php';
  static const String vendorDashboard = '/vendor/dashboard.php';
  static const String vendorStats = '/vendor/stats.php';
  static const String vendorEnquiries = '/enquiries/vendor-list.php';
  static const String vendorDocuments = '/vendor/documents.php';
  static const String vendorUploadDocument = '/vendor/upload-document.php';

  static const String categories = '/categories/list.php';
  static const String categoryProducts = '/categories/products.php';
  static const String categoryServices = '/categories/services.php';
  static const String subcategories = '/subcategories/list.php';

  static const String products = '/products/list.php';
  // Products grouped by subcategory for a single category
  static const String productsByCategorySubcategories =
      '/products/by_category_subcategories.php';
  static const String productDetail = '/products/detail.php';
  static const String productCreate = '/products/create.php';
  static const String productUpdate = '/products/update.php';
  static const String productDelete = '/products/delete.php';
  static const String vendorProducts = '/products/vendor-list.php';

  static const String services = '/services/list.php';
  static const String serviceDetail = '/services/detail.php';
  static const String serviceCreate = '/services/create.php';
  static const String serviceUpdate = '/services/update.php';
  static const String serviceDelete = '/services/delete.php';
  static const String vendorServices = '/services/vendor-list.php';

  static const String enquiryCreate = '/enquiries/create.php';
  static const String enquiryList = '/enquiries/list.php';
  static const String enquiryDetail = '/enquiries/detail.php';
  static const String enquiryRespond = '/enquiries/respond.php';

  static const String chatList = '/chat/list.php';
  static const String chatMessages = '/chat/messages.php';
  static const String chatSend = '/chat/send.php';

  static const String couponValidate = '/coupons/validate.php';

  static const String paymentCreate = '/payments/create.php';
  static const String paymentVerify = '/payments/verify.php';
  static const String vendorPaymentCreate =
      '/payments/create.php'; // Use existing endpoint
  static const String vendorPaymentVerify =
      '/payments/verify.php'; // Use existing endpoint

  static const String notifications = '/notifications/list.php';
  static const String notificationRead = '/notifications/read.php';

  static const String search = '/search/index.php';

  static const String banners = '/banners/list.php';

  // Reviews endpoints
  static const String reviewsList = '/reviews/list.php';
  static const String reviewsCreate = '/reviews/create.php';
  static const String reviewsDelete = '/reviews/delete.php';
  static const String reviewsStats = '/reviews/stats.php';
}
