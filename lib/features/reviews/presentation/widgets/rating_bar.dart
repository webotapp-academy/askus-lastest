import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';

class RatingBar extends StatelessWidget {
  final int rating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showValue;

  const RatingBar({
    super.key,
    required this.rating,
    this.size = 16,
    this.activeColor,
    this.inactiveColor,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: index < rating
                ? (activeColor ?? AppColors.warning)
                : (inactiveColor ?? AppColors.border),
          );
        }),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(
            rating.toString(),
            style: TextStyle(
              fontSize: size * 0.75,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveRatingBar extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const InteractiveRatingBar({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starRating = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(starRating),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starRating <= rating
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              size: size,
              color: starRating <= rating
                  ? (activeColor ?? AppColors.warning)
                  : (inactiveColor ?? AppColors.border),
            ),
          ),
        );
      }),
    );
  }
}

class RatingStatsWidget extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;

  const RatingStatsWidget({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Average rating
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                RatingBar(rating: averageRating.round(), size: 20),
                const SizedBox(height: 4),
                Text(
                  '$totalReviews reviews',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Distribution bars
          Expanded(
            flex: 3,
            child: Column(
              children: List.generate(5, (index) {
                final rating = 5 - index;
                final count = distribution[rating] ?? 0;
                final percentage =
                    totalReviews > 0 ? (count / totalReviews) * 100 : 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$rating',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star_rounded,
                          size: 12, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: AppColors.border,
                            valueColor:
                                AlwaysStoppedAnimation(AppColors.warning),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
