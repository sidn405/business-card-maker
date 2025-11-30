enum SubscriptionTier {
  free,
  premium,
  business,
}

class Subscription {
  final SubscriptionTier tier;
  final DateTime? expiryDate;
  final bool isActive;

  Subscription({
    required this.tier,
    this.expiryDate,
    required this.isActive,
  });

  // Feature limits
  int get maxCards {
    switch (tier) {
      case SubscriptionTier.free:
        return 3;
      case SubscriptionTier.premium:
        return -1; // Unlimited
      case SubscriptionTier.business:
        return -1; // Unlimited
    }
  }

  bool get hasCustomTemplates {
    return tier != SubscriptionTier.free;
  }

  bool get hasColorThemes {
    return tier != SubscriptionTier.free;
  }

  bool get hasCompanyLogos {
    return tier != SubscriptionTier.free;
  }

  bool get hasAIResume {
    return tier == SubscriptionTier.business;
  }

  bool get hasQRCodes {
    return tier != SubscriptionTier.free;
  }

  bool get hasBulkExport {
    return tier == SubscriptionTier.business;
  }

  String get displayName {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.business:
        return 'Business';
    }
  }

  String get description {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Up to 3 cards, basic features';
      case SubscriptionTier.premium:
        return 'Unlimited cards, custom designs, themes';
      case SubscriptionTier.business:
        return 'Everything + AI Resume Builder';
    }
  }

  double get monthlyPrice {
    switch (tier) {
      case SubscriptionTier.free:
        return 0.0;
      case SubscriptionTier.premium:
        return 4.99;
      case SubscriptionTier.business:
        return 9.99;
    }
  }

  double get yearlyPrice {
    switch (tier) {
      case SubscriptionTier.free:
        return 0.0;
      case SubscriptionTier.premium:
        return 29.99;
      case SubscriptionTier.business:
        return 59.99;
    }
  }

  // Product IDs for Google Play / App Store
  static String getMonthlyProductId(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.premium:
        return 'prostack_premium';
      case SubscriptionTier.business:
        return 'prostack_business';
      default:
        return '';
    }
  }

  static String getYearlyProductId(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.premium:
        return 'prostack_premium_yearly';
      case SubscriptionTier.business:
        return 'prostack_business_yearly';
      default:
        return '';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier.toString(),
      'expiryDate': expiryDate?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.toString() == json['tier'],
        orElse: () => SubscriptionTier.free,
      ),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      isActive: json['isActive'] ?? false,
    );
  }

  static Subscription free() {
    return Subscription(
      tier: SubscriptionTier.free,
      isActive: true,
    );
  }
}
