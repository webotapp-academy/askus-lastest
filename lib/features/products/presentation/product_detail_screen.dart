import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/product_provider.dart';
import '../../enquiries/presentation/create_enquiry_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _imageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().fetchProductDetail(widget.productId);
      }
    });
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading || provider.currentProduct == null) {
            return const LoadingWidget();
          }

          final product = provider.currentProduct!;

          return CustomScrollView(
            slivers: [
              _buildAppBar(product),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGallery(product),
                    _buildProductInfo(product),
                    _buildDescription(product),
                    _buildVendorInfo(product),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar(dynamic product) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, size: 20),
          onPressed: () => HapticFeedback.lightImpact(),
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border_rounded, size: 20),
          onPressed: () => HapticFeedback.lightImpact(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildImageGallery(dynamic product) {
    final images = product.images.isNotEmpty ? product.images : [''];

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: PageView.builder(
              controller: _imageController,
              onPageChanged: (index) =>
                  setState(() => _currentImageIndex = index),
              itemCount: images.length,
              itemBuilder: (context, index) {
                if (images[index].isEmpty) {
                  return Container(
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(Icons.image_outlined,
                          size: 60, color: AppColors.textSecondary),
                    ),
                  );
                }
                return Image.network(
                  images[index],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_outlined,
                          size: 60, color: AppColors.textSecondary),
                    ),
                  ),
                );
              },
            ),
          ),
          if (images.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: index == _currentImageIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _currentImageIndex
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildProductInfo(dynamic product) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.hasDiscount)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product.discountPercent.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        color: AppColors.warning, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      product.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (product.vendorName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.store_outlined,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Sold by ${product.vendorName}',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${product.price.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
              if (product.hasDiscount) ...[
                const SizedBox(width: 8),
                Text(
                  '₹${product.comparePrice!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: product.inStock
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  product.inStock
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 14,
                  color: product.inStock ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  product.inStock ? 'In Stock' : 'Out of Stock',
                  style: TextStyle(
                    color:
                        product.inStock ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(dynamic product) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              const Text('Description',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.description ?? 'No description available',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorInfo(dynamic product) {
    if (product.vendorName == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_rounded,
                  color: AppColors.secondary, size: 16),
              const SizedBox(width: 6),
              const Text('Seller',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.store_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.vendorName!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                      Row(
                        children: [
                          Icon(Icons.verified,
                              color: AppColors.success, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            'Verified',
                            style: TextStyle(
                                color: AppColors.success, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.currentProduct == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2)),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateEnquiryScreen(
                                type: 'product',
                                itemId: widget.productId,
                                itemName: provider.currentProduct!.name,
                                vendorId: provider.currentProduct!.vendorId,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mail_outline_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Send Enquiry',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => HapticFeedback.lightImpact(),
                      borderRadius: BorderRadius.circular(10),
                      child: Icon(Icons.chat_bubble_outline_rounded,
                          color: AppColors.success, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
