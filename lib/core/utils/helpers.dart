import 'package:intl/intl.dart';

class Helpers {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
  }

  static String getDistanceString(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    }
    return '${distanceInKm.toStringAsFixed(1)} km';
  }

  static String fixImageUrl(String? url) {
    if (url == null) return '';
    String cleaned = url.trim();
    if (cleaned.isEmpty) return '';

    // Fix legacy / broken domain to working domain
    if (cleaned.contains('indiawebdesigns.in/app/askus/')) {
      cleaned = cleaned.replaceAll('indiawebdesigns.in/app/askus/', 'apps.indiawebdesigns.in/askus/');
    } else if (cleaned.contains('indiawebdesigns.in/askus/')) {
      cleaned = cleaned.replaceAll('indiawebdesigns.in/askus/', 'apps.indiawebdesigns.in/askus/');
    }

    // Fix relative paths starting with /
    if (cleaned.startsWith('/')) {
      return 'https://apps.indiawebdesigns.in/askus$cleaned';
    }

    // Fix relative paths like images/1.jpg or uploads/...
    if (!cleaned.startsWith('http://') &&
        !cleaned.startsWith('https://') &&
        !cleaned.startsWith('assets/')) {
      return 'https://apps.indiawebdesigns.in/askus/$cleaned';
    }

    // Ensure HTTPS if pointing to apps.indiawebdesigns.in
    if (cleaned.startsWith('http://apps.indiawebdesigns.in')) {
      cleaned = cleaned.replaceFirst('http://', 'https://');
    }

    return cleaned;
  }
}
