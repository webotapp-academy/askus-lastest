class SubscriptionPlan {
  final int id;
  final String name;
  final String targetGroup;
  final double price;
  final int durationDays;
  final int maxListings;
  final int featuredDays;
  final int boostDays;
  final bool hasTrustedBadge;
  final bool hasVerifiedBadge;
  final bool hasTopPlacement;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.targetGroup,
    required this.price,
    required this.durationDays,
    required this.maxListings,
    required this.featuredDays,
    required this.boostDays,
    required this.hasTrustedBadge,
    required this.hasVerifiedBadge,
    required this.hasTopPlacement,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      targetGroup: json['target_group']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      durationDays: int.tryParse(json['duration_days']?.toString() ?? '0') ?? 0,
      maxListings: int.tryParse(json['max_listings']?.toString() ?? '0') ?? 0,
      featuredDays: int.tryParse(json['featured_days']?.toString() ?? '0') ?? 0,
      boostDays: int.tryParse(json['boost_days']?.toString() ?? '0') ?? 0,
      hasTrustedBadge:
          json['has_trusted_badge'] == 1 || json['has_trusted_badge'] == true,
      hasVerifiedBadge:
          json['has_verified_badge'] == 1 || json['has_verified_badge'] == true,
      hasTopPlacement:
          json['has_top_placement'] == 1 || json['has_top_placement'] == true,
    );
  }
}
