import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../auth/data/auth_provider.dart';
import '../../location/data/location_provider.dart';
import '../data/category_provider.dart';
import '../data/category_model.dart';
import '../../products/presentation/product_list_screen.dart';
import '../../services/presentation/service_list_screen.dart';
import '../../services/presentation/service_detail_screen.dart';
import '../../services/data/service_model.dart';
import '../../enquiries/presentation/enquiry_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../../services/data/service_provider.dart';
import '../../products/data/product_provider.dart';
import '../../banners/data/banner_provider.dart';
import '../../notifications/presentation/notification_screen.dart';
import '../../products/presentation/vendor_products_screen.dart';
import '../../services/presentation/vendor_services_screen.dart';
import '../../vendor/presentation/vendor_dashboard_screen.dart';
import '../../vendor/presentation/vendor_profile_screen.dart';
import 'search_screen.dart';

const _sectionTitleStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w600,
  color: AppColors.textPrimary,
);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CategoryProvider>().fetchCategories();
        context.read<ProductProvider>().fetchProducts(refresh: true);
        context.read<ServiceProvider>().fetchServices(refresh: true);
        context.read<BannerProvider>().fetchBanners();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isVendor = authProvider.isVendor;

    final pages = isVendor
        ? [
            const VendorDashboardScreen(),
            const VendorProductsScreen(),
            const VendorServicesScreen(),
            const EnquiryListScreen(),
            const VendorProfileScreen(),
          ]
        : [
            const _UserHomeTab(),
            const ProductListScreen(),
            const ServiceListScreen(),
            const EnquiryListScreen(),
            const ProfileScreen(),
          ];

    final bottomNavItems = isVendor
        ? const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_rounded), label: 'Products'),
            BottomNavigationBarItem(
                icon: Icon(Icons.build_circle_rounded), label: 'Services'),
            BottomNavigationBarItem(
                icon: Icon(Icons.mail_rounded), label: 'Enquiries'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'Profile'),
          ]
        : const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_rounded), label: 'Products'),
            BottomNavigationBarItem(
                icon: Icon(Icons.handyman_rounded), label: 'Services'),
            BottomNavigationBarItem(
                icon: Icon(Icons.mail_rounded), label: 'Enquiries'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'Profile'),
          ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          items: bottomNavItems,
        ),
      ),
    );
  }
}

class _UserHomeTab extends StatefulWidget {
  const _UserHomeTab();

  @override
  State<_UserHomeTab> createState() => _UserHomeTabState();
}

class _UserHomeTabState extends State<_UserHomeTab> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();
    final categories = context.watch<CategoryProvider>();
    final products = context.watch<ProductProvider>();
    final banners = context.watch<BannerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            categories.fetchCategories(),
            products.fetchProducts(refresh: true),
            banners.fetchBanners(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(location),
            _buildSearchBar(),
            if (banners.homeTopBanners.isNotEmpty)
              _buildBannerCarousel(banners),
            _buildCategoriesSection(categories),
            _buildFeaturedProductsSection(products),
            _buildFeaturedServicesSection(context),
            if (banners.homeMiddleBanners.isNotEmpty)
              _buildPromoBanner(banners),
            _buildAllProductsSection(products),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(LocationProvider location) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ask Us',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {},
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location.currentAddress ?? 'Set your location',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down,
                            color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.primary,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products, services...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppColors.primary, size: 22),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            readOnly: true,
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel(BannerProvider banners) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        height: 150,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _bannerController,
                onPageChanged: (index) =>
                    setState(() => _currentBannerIndex = index),
                itemCount: banners.homeTopBanners.length,
                itemBuilder: (context, index) {
                  final banner = banners.homeTopBanners[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        banner.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              banner.title ?? 'Special Offer',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.homeTopBanners.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: index == _currentBannerIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _currentBannerIndex
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(CategoryProvider categories) {
    print('🏠 HomeScreen: Building categories section');
    print(
        '📦 HomeScreen: isLoading=${categories.isLoading}, categories=${categories.categories.length}, parentCategories=${categories.parentCategories.length}');

    if (categories.error != null) {
      print('❌ HomeScreen: Category error - ${categories.error}');
    }

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Shop by Category', style: _sectionTitleStyle),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProductListScreen()),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                  ),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (categories.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (categories.error != null)
              Center(
                child: Text(
                  'Error: ${categories.error}',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              )
            else if (categories.parentCategories.isEmpty)
              const Center(
                child: Text(
                  'No categories found',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.95,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: categories.parentCategories.take(8).length,
                itemBuilder: (context, index) {
                  final category = categories.parentCategories[index];
                  return _CategoryCard(category: category);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedProductsSection(ProductProvider products) {
    final displayProducts = products.products.take(6).toList();

    if (displayProducts.isEmpty && !products.isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                const SizedBox(width: 6),
                const Text('Featured Products', style: _sectionTitleStyle),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProductListScreen()),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                  ),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            products.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: displayProducts.length,
                      itemBuilder: (context, index) {
                        final product = displayProducts[index];
                        return _ProductCard(product: product);
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedServicesSection(BuildContext context) {
    final services = context.watch<ServiceProvider>();
    final featuredServices =
        services.services.where((s) => s.isFeatured).take(6).toList();
    final displayServices = featuredServices.isNotEmpty
        ? featuredServices
        : services.services.take(6).toList();

    if (displayServices.isEmpty && !services.isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build_circle_rounded,
                    color: AppColors.secondary, size: 18),
                const SizedBox(width: 6),
                const Text('Featured Services', style: _sectionTitleStyle),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ServiceListScreen()),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                  ),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            services.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: displayServices.length,
                      itemBuilder: (context, index) {
                        final service = displayServices[index];
                        return _ServiceCard(service: service);
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BannerProvider banners) {
    if (banners.homeMiddleBanners.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    final banner = banners.homeMiddleBanners.first;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            banner.image,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success, AppColors.primary],
                ),
              ),
              child: Center(
                child: Text(
                  banner.title ?? 'Special Promotion',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllProductsSection(ProductProvider products) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 6),
                const Text('Popular Products', style: _sectionTitleStyle),
              ],
            ),
            const SizedBox(height: 10),
            products.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.products.take(6).length,
                      itemBuilder: (context, index) {
                        final product = products.products[index];
                        return _ProductCard(product: product);
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;

  const _CategoryCard({required this.category});

  IconData _getCategoryIcon() {
    // First check if category has an icon field from database
    if (category.icon != null && category.icon!.isNotEmpty) {
      // Handle Font Awesome class names (fa fa-icon-name)
      String iconName = category.icon!.toLowerCase();

      // Remove 'fa fa-' prefix if present
      if (iconName.startsWith('fa fa-')) {
        iconName = iconName.substring(6);
      } else if (iconName.startsWith('fa-')) {
        iconName = iconName.substring(3);
      }

      // Map Font Awesome icon names to Material Icons
      switch (iconName) {
        case 'hard-hat':
        case 'helmet-safety':
          return Icons.construction_rounded;
        case 'industry':
        case 'factory':
          return Icons.factory_rounded;
        case 'tools':
        case 'wrench':
          return Icons.build_rounded;
        case 'bolt':
        case 'lightning':
          return Icons.electrical_services_rounded;
        case 'paint-roller':
        case 'paint-brush':
          return Icons.format_paint_rounded;
        case 'building':
        case 'home':
          return Icons.apartment_rounded;
        case 'hammer':
          return Icons.construction_rounded;
        case 'screwdriver':
          return Icons.build_rounded;
        case 'pipe':
        case 'faucet':
          return Icons.plumbing_rounded;
        case 'broom':
        case 'cleaning':
          return Icons.cleaning_services_rounded;
        case 'car':
        case 'truck':
          return Icons.local_shipping_rounded;
        case 'leaf':
        case 'tree':
          return Icons.eco_rounded;
        case 'shield':
        case 'security':
          return Icons.security_rounded;
        case 'camera':
          return Icons.camera_alt_rounded;
        case 'wifi':
        case 'signal':
          return Icons.wifi_rounded;
        case 'phone':
          return Icons.phone_rounded;
        case 'laptop':
        case 'computer':
          return Icons.computer_rounded;
        case 'mobile':
        case 'mobile-phone':
          return Icons.smartphone_rounded;
        case 'heart':
        case 'medical':
          return Icons.medical_services_rounded;
        case 'utensils':
        case 'cutlery':
          return Icons.restaurant_rounded;
        case 'shopping-cart':
        case 'cart':
          return Icons.shopping_cart_rounded;
        case 'tshirt':
        case 'shirt':
          return Icons.checkroom_rounded;
        case 'gem':
        case 'diamond':
          return Icons.diamond_rounded;
        case 'graduation-cap':
        case 'book':
          return Icons.school_rounded;
        case 'gamepad':
        case 'game':
          return Icons.sports_esports_rounded;
        case 'music':
        case 'musical-note':
          return Icons.music_note_rounded;
        case 'film':
        case 'video':
          return Icons.movie_rounded;
        default:
          return Icons.category_rounded;
      }
    }

    // Fallback to slug-based mapping
    final slug = category.slug.toLowerCase();
    if (slug.contains('construction')) {
      return Icons.construction_rounded;
    } else if (slug.contains('building') || slug.contains('material')) {
      return Icons.apartment_rounded;
    } else if (slug.contains('tool')) {
      return Icons.build_rounded;
    } else if (slug.contains('electrical') || slug.contains('plumbing')) {
      return Icons.electrical_services_rounded;
    } else if (slug.contains('interior') || slug.contains('renovation')) {
      return Icons.format_paint_rounded;
    } else if (slug.contains('service')) {
      return Icons.build_circle_rounded;
    } else {
      return Icons.category_rounded;
    }
  }

  Color _getCategoryColor() {
    // First check if category has an icon field for color mapping
    if (category.icon != null && category.icon!.isNotEmpty) {
      String iconName = category.icon!.toLowerCase();

      // Remove 'fa fa-' prefix if present
      if (iconName.startsWith('fa fa-')) {
        iconName = iconName.substring(6);
      } else if (iconName.startsWith('fa-')) {
        iconName = iconName.substring(3);
      }

      switch (iconName) {
        case 'hard-hat':
        case 'helmet-safety':
          return const Color(0xFFF59E0B); // Orange for construction
        case 'industry':
        case 'factory':
          return const Color(0xFF6B7280); // Gray for industry
        case 'tools':
        case 'wrench':
        case 'hammer':
        case 'screwdriver':
          return const Color(0xFF8B5CF6); // Purple for tools
        case 'bolt':
        case 'lightning':
          return const Color(0xFFF59E0B); // Orange for electrical
        case 'paint-roller':
        case 'paint-brush':
          return const Color(0xFFEC4899); // Pink for painting
        case 'building':
        case 'home':
          return const Color(0xFF10B981); // Green for buildings
        case 'pipe':
        case 'faucet':
          return const Color(0xFF0EA5E9); // Blue for plumbing
        case 'broom':
        case 'cleaning':
          return const Color(0xFF10B981); // Green for cleaning
        case 'car':
        case 'truck':
          return const Color(0xFF3B82F6); // Blue for automotive
        case 'leaf':
        case 'tree':
          return const Color(0xFF10B981); // Green for landscaping
        case 'shield':
        case 'security':
          return const Color(0xFFEF4444); // Red for security
        case 'camera':
          return const Color(0xFF8B5CF6); // Purple for photography
        case 'wifi':
        case 'signal':
        case 'laptop':
        case 'computer':
        case 'mobile':
        case 'mobile-phone':
          return const Color(0xFF3B82F6); // Blue for tech
        case 'heart':
        case 'medical':
          return const Color(0xFFEF4444); // Red for medical
        case 'utensils':
        case 'cutlery':
          return const Color(0xFFF59E0B); // Orange for food
        case 'shopping-cart':
        case 'cart':
          return const Color(0xFF10B981); // Green for shopping
        case 'tshirt':
        case 'shirt':
          return const Color(0xFFEC4899); // Pink for fashion
        case 'gem':
        case 'diamond':
          return const Color(0xFF8B5CF6); // Purple for jewelry
        case 'graduation-cap':
        case 'book':
          return const Color(0xFF3B82F6); // Blue for education
        case 'gamepad':
        case 'game':
          return const Color(0xFFEF4444); // Red for gaming
        case 'music':
        case 'musical-note':
          return const Color(0xFF8B5CF6); // Purple for music
        case 'film':
        case 'video':
          return const Color(0xFF6B7280); // Gray for media
        default:
          return AppColors.primary;
      }
    }

    // Fallback to slug-based mapping
    final slug = category.slug.toLowerCase();
    if (slug.contains('construction')) {
      return const Color(0xFFF59E0B);
    } else if (slug.contains('building') || slug.contains('material')) {
      return const Color(0xFF6B7280);
    } else if (slug.contains('tool')) {
      return const Color(0xFF8B5CF6);
    } else if (slug.contains('electrical') || slug.contains('plumbing')) {
      return const Color(0xFF0EA5E9);
    } else if (slug.contains('interior') || slug.contains('renovation')) {
      return const Color(0xFFEC4899);
    } else if (slug.contains('service')) {
      return const Color(0xFF8B5CF6);
    } else {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductListScreen(
              categoryId: category.id, categoryName: category.name),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(100), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: category.image != null && category.image!.isNotEmpty
                  ? Image.network(
                      category.image!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: color.withAlpha(25),
                          child: Icon(
                            _getCategoryIcon(),
                            color: color,
                            size: 24,
                          ),
                        );
                      },
                    )
                  : Icon(_getCategoryIcon(), color: color, size: 24),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category.name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    print('🖼️ ProductCard: ${product.name}, thumbnail=${product.thumbnail}');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id)),
      ),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Container(
                    height: 90,
                    width: double.infinity,
                    color: AppColors.background,
                    child: product.thumbnail != null &&
                            product.thumbnail!.isNotEmpty
                        ? Image.network(
                            product.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              size: 30,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            size: 30,
                            color: AppColors.textSecondary,
                          ),
                  ),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '₹${product.comparePrice!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 9,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final dynamic product;

  const _ProductGridCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.background,
                      child: product.thumbnail != null &&
                              product.thumbnail!.isNotEmpty
                          ? Image.network(
                              product.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 30,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 30,
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product.discountPercent.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '₹${product.comparePrice!.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VendorHomeTab extends StatelessWidget {
  const _VendorHomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final vendorProfile = auth.user?.vendorProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.store_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendorProfile?.storeName ?? 'Your Store',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${vendorProfile?.rating ?? 0}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            if (vendorProfile?.isVerified == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified,
                                        color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Stats',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        icon: Icons.inventory_2,
                        title: 'Products',
                        value: '0',
                        color: AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                        icon: Icons.build_circle,
                        title: 'Services',
                        value: '0',
                        color: AppColors.secondary)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        icon: Icons.mail,
                        title: 'Enquiries',
                        value: '0',
                        color: AppColors.warning)),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                        icon: Icons.star,
                        title: 'Reviews',
                        value: '0',
                        color: AppColors.success)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(serviceId: service.id)),
      ),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: Container(
                    height: 90,
                    width: double.infinity,
                    color: AppColors.background,
                    child: service.thumbnail != null &&
                            service.thumbnail!.isNotEmpty
                        ? Image.network(
                            service.thumbnail!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.build_rounded,
                              size: 30,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : const Icon(
                            Icons.build_rounded,
                            size: 30,
                            color: AppColors.textSecondary,
                          ),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SERVICE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${service.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      if (service.rating > 0) ...[
                        Icon(Icons.star, size: 10, color: Colors.amber),
                        Text(
                          ' ${service.rating.toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 9),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
