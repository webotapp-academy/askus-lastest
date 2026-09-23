import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/service_model.dart';
import '../data/service_provider.dart';
import '../../enquiries/presentation/create_enquiry_screen.dart';
import '../../reviews/presentation/reviews_list_screen.dart';
import '../../reviews/presentation/write_review_screen.dart';
import '../../reviews/data/review_provider.dart';
import '../../reviews/presentation/widgets/rating_bar.dart';

class ServiceDetailScreen extends StatefulWidget {
  final int serviceId;
  final Service? initialService;

  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    this.initialService,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  int _currentImageIndex = 0;
  final PageController _imageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.initialService != null) {
          context.read<ServiceProvider>().setInitialService(widget.initialService!);
        }
        context.read<ServiceProvider>().fetchServiceDetail(widget.serviceId);
        // Load reviews for this service's vendor
        context.read<ReviewProvider>().fetchReviews(
              type: 'vendor',
              itemId: widget
                  .serviceId, // This will be used to get vendor_id from service
              refresh: true,
            );
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
      body: Consumer<ServiceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingWidget();
          }

          if (provider.error != null || provider.currentService == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    provider.error ?? 'Service not found',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final service = provider.currentService!;

          return CustomScrollView(
            slivers: [
              _buildAppBar(service),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGallery(service),
                    _buildServiceInfo(service),
                    _buildDescription(service),
                    _buildVendorInfo(service),
                    _buildReviewsSection(service),
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

  Widget _buildAppBar(dynamic service) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
    );
  }

  Widget _buildImageGallery(dynamic service) {
    final images = service.images.isNotEmpty ? service.images : [''];

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
                      child: Icon(Icons.handyman_rounded,
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

  Widget _buildServiceInfo(dynamic service) {
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.handyman_rounded,
                              color: AppColors.secondary, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            'SERVICE',
                            style: TextStyle(
                                color: AppColors.secondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      service.name,
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
                      service.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (service.vendorName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.store_outlined,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Provided by ${service.vendorName}',
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
                '₹${service.price.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
              if (service.duration != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        service.duration!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(dynamic service) {
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
              const Text('About Service',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            service.description,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorInfo(dynamic service) {
    if (service.vendorName == null) return const SizedBox.shrink();

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
              const Text('Service Provider',
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
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.handyman_rounded,
                      color: AppColors.secondary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.vendorName!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                      Row(
                        children: [
                          Icon(Icons.verified,
                              color: AppColors.success, size: 10),
                          const SizedBox(width: 2),
                          Text(
                            'Verified Provider',
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

  Widget _buildReviewsSection(dynamic service) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        return Container(
          color: Colors.white,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Reviews ${reviewProvider.stats != null ? "(${reviewProvider.stats!.totalReviews})" : ""}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (reviewProvider.reviews.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: context.read<ReviewProvider>(),
                              child: ReviewsListScreen(
                                type: 'vendor',
                                itemId: service.vendorId,
                                vendorId: service.vendorId,
                                itemName: service.name,
                                itemImage: service.images.isNotEmpty
                                    ? service.images[0]
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('See All'),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Rating summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          reviewProvider.stats?.averageRating
                                  .toStringAsFixed(1) ??
                              service.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        RatingBar(
                            rating:
                                reviewProvider.stats?.averageRating.round() ??
                                    service.rating.round(),
                            size: 14),
                        if (reviewProvider.stats != null)
                          Text(
                            '${reviewProvider.stats!.totalReviews} reviews',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChangeNotifierProvider.value(
                                value: context.read<ReviewProvider>(),
                                child: WriteReviewScreen(
                                  type: 'vendor',
                                  itemId: service.vendorId,
                                  vendorId: service.vendorId,
                                  itemName: service.name,
                                  itemImage: service.images.isNotEmpty
                                      ? service.images[0]
                                      : null,
                                ),
                              ),
                            ),
                          ).then((_) {
                            // Refresh reviews after writing a review
                            context.read<ReviewProvider>().fetchReviews(
                                  type: 'vendor',
                                  itemId: service.vendorId,
                                  refresh: true,
                                );
                          });
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Write a Review'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Show recent reviews
              if (reviewProvider.reviews.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Recent Reviews',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...reviewProvider.reviews
                    .take(2)
                    .map((review) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.border.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      review.userName ?? 'Anonymous',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    RatingBar(rating: review.rating, size: 12),
                                    const Spacer(),
                                    Text(
                                      review.timeAgo,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (review.title != null &&
                                    review.title!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    review.title!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (review.comment != null &&
                                    review.comment!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    review.comment!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ] else if (!reviewProvider.isLoading) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 32,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No reviews yet',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to review this service!',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Consumer<ServiceProvider>(
      builder: (context, provider, _) {
        if (provider.currentService == null) return const SizedBox.shrink();

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
                          colors: [AppColors.secondary, AppColors.primary]),
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
                                type: 'service',
                                itemId: widget.serviceId,
                                itemName: provider.currentService!.name,
                                vendorId: provider.currentService!.vendorId,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Book Now',
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
              ],
            ),
          ),
        );
      },
    );
  }
}
