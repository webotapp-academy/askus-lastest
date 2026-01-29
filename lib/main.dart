import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/data/auth_provider.dart';
import 'features/location/data/location_provider.dart';
import 'features/categories/data/category_provider.dart';
import 'features/products/data/product_provider.dart';
import 'features/services/data/service_provider.dart';
import 'features/enquiries/data/enquiry_provider.dart';
import 'features/chat/data/chat_provider.dart';
import 'features/notifications/data/notification_provider.dart';
import 'features/banners/data/banner_provider.dart';
import 'features/vendor/data/vendor_provider.dart';
import 'features/reviews/data/review_provider.dart';
import 'features/auth/presentation/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AskUsApp());
}

class AskUsApp extends StatelessWidget {
  const AskUsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => EnquiryProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => BannerProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: MaterialApp(
        title: 'Ask Us',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
