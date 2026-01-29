import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_theme.dart';
import '../data/review_provider.dart';
import 'widgets/rating_bar.dart';
import 'widgets/review_card.dart';
import 'write_review_screen.dart';

class ReviewsListScreen extends StatefulWidget {
  final String type;
  final int itemId;
  final int vendorId;
  final String itemName;
  final String? itemImage;

  const ReviewsListScreen({
    super.key,
    required this.type,
    required this.itemId,
    required this.vendorId,
    required this.itemName,
    this.itemImage,
  });

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadReviews() {
    context.read<ReviewProvider>().fetchReviews(
          type: widget.type,
          itemId: widget.itemId,
          refresh: true,
        );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ReviewProvider>().fetchReviews(
            type: widget.type,
            itemId: widget.itemId,
          );
    }
  }

  Future<void> _navigateToWriteReview() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(
          type: widget.type,
          itemId: widget.itemId,
          vendorId: widget.vendorId,
          itemName: widget.itemName,
          itemImage: widget.itemImage,
        ),
      ),
    );

    if (result == true) {
      _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _navigateToWriteReview,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Write'),
          ),
        ],
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.reviews.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReviews,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadReviews(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Stats section
                if (provider.stats != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: RatingStatsWidget(
                        averageRating: provider.stats!.averageRating,
                        totalReviews: provider.stats!.totalReviews,
                        distribution: provider.stats!.ratingDistribution,
                      ),
                    ),
                  ),

                // Reviews list
                if (provider.reviews.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reviews yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to review!',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _navigateToWriteReview,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Write a Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= provider.reviews.length) {
                            return provider.hasMore
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReviewCard(review: provider.reviews[index]),
                          );
                        },
                        childCount: provider.reviews.length + 1,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToWriteReview,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit_outlined, color: Colors.white),
        label: const Text(
          'Write Review',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
