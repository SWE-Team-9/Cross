class Plan {
  final String id;
  final String code;
  final String name;
  final String tier;
  final int priceCents;
  final String priceDisplay;
  final String? billingInterval;
  final int uploadLimit;
  final String uploadLimitDisplay;
  final bool isUnlimited;
  final int trialDays;
  final bool adsEnabled;
  final bool canDownload;
  final String supportLevel;
  final List<String> highlightedFeatures;

  /// Legacy fields kept so old premium/upload callers do not break while
  /// we upgrade the feature file by file.
  final double price;
  final String description;
  final String interval;

  const Plan({
    this.id = '',
    this.code = '',
    this.name = '',
    this.tier = '',
    this.priceCents = 0,
    this.priceDisplay = '',
    this.billingInterval,
    this.uploadLimit = 0,
    this.uploadLimitDisplay = '',
    this.isUnlimited = false,
    this.trialDays = 0,
    this.adsEnabled = true,
    this.canDownload = false,
    this.supportLevel = 'community',
    this.highlightedFeatures = const <String>[],
    this.price = 0.0,
    this.description = '',
    this.interval = 'month',
  });

  bool get isFree => normalizedCode == 'FREE';

  bool get isPremium => !isFree;

  bool get isPro => normalizedCode == 'PRO';

  bool get isGoPlus => normalizedCode == 'GO_PLUS';

  String get normalizedCode => code.trim().toUpperCase();

  String get normalizedTier => tier.trim().toUpperCase();

  String get displayName => name.trim().isEmpty ? normalizedCode : name;

  String get displayPrice {
    if (priceDisplay.trim().isNotEmpty) {
      return priceDisplay;
    }

    if (priceCents <= 0) {
      return 'Free';
    }

    final dollars = priceCents / 100;
    final amount = dollars == dollars.roundToDouble()
        ? dollars.toStringAsFixed(0)
        : dollars.toStringAsFixed(2);

    final suffix = normalizedBillingInterval == 'MONTHLY' ? '/mo' : '';
    return '\$$amount$suffix';
  }

  String get displayUploadLimit {
    if (isUnlimited) {
      return 'Unlimited';
    }

    if (uploadLimitDisplay.trim().isNotEmpty) {
      return uploadLimitDisplay;
    }

    return uploadLimit.toString();
  }

  String get normalizedBillingInterval =>
      (billingInterval ?? interval).trim().toUpperCase();

  String get billingIntervalLabel {
    switch (normalizedBillingInterval) {
      case 'MONTHLY':
        return 'Monthly';
      case 'YEARLY':
      case 'ANNUAL':
        return 'Yearly';
      default:
        return normalizedBillingInterval.isEmpty
            ? ''
            : normalizedBillingInterval[0] +
                normalizedBillingInterval.substring(1).toLowerCase();
    }
  }

  factory Plan.fromJson(Map<String, dynamic> json) {
    final int parsedPriceCents = _asInt(
      json['priceCents'] ?? json['price_cents'],
    );

    final double parsedLegacyPrice = _asDouble(
      json['price'],
      fallback: parsedPriceCents / 100,
    );

    final String? parsedBillingInterval = _asNullableString(
      json['billingInterval'] ?? json['billing_interval'],
    );

    final List<String> parsedFeatures = _asStringList(
      json['highlightedFeatures'] ?? json['highlighted_features'],
    );

    return Plan(
      id: _asString(json['id']),
      code: _asString(json['code']),
      name: _asString(json['name']),
      tier: _asString(json['tier'] ?? json['subscriptionTier']),
      priceCents: parsedPriceCents,
      priceDisplay: _asString(json['priceDisplay'] ?? json['price_display']),
      billingInterval: parsedBillingInterval,
      uploadLimit: _asInt(json['uploadLimit'] ?? json['upload_limit']),
      uploadLimitDisplay: _asString(
        json['uploadLimitDisplay'] ?? json['upload_limit_display'],
      ),
      isUnlimited: _asBool(json['isUnlimited'] ?? json['is_unlimited']),
      trialDays: _asInt(json['trialDays'] ?? json['trial_days']),
      adsEnabled: _asBool(
        json['adsEnabled'] ?? json['ads_enabled'],
        fallback: true,
      ),
      canDownload: _asBool(json['canDownload'] ?? json['can_download']),
      supportLevel: _asString(
        json['supportLevel'] ?? json['support_level'],
        fallback: 'community',
      ),
      highlightedFeatures: parsedFeatures,
      price: parsedLegacyPrice,
      description: _asString(
        json['description'],
        fallback: parsedFeatures.join(' • '),
      ),
      interval: _legacyInterval(parsedBillingInterval),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'code': code,
      'name': name,
      'tier': tier,
      'priceCents': priceCents,
      'priceDisplay': priceDisplay,
      'billingInterval': billingInterval,
      'uploadLimit': uploadLimit,
      'uploadLimitDisplay': uploadLimitDisplay,
      'isUnlimited': isUnlimited,
      'trialDays': trialDays,
      'adsEnabled': adsEnabled,
      'canDownload': canDownload,
      'supportLevel': supportLevel,
      'highlightedFeatures': highlightedFeatures,
      'price': price,
      'description': description,
      'interval': interval,
    };
  }

  Plan copyWith({
    String? id,
    String? code,
    String? name,
    String? tier,
    int? priceCents,
    String? priceDisplay,
    String? billingInterval,
    bool clearBillingInterval = false,
    int? uploadLimit,
    String? uploadLimitDisplay,
    bool? isUnlimited,
    int? trialDays,
    bool? adsEnabled,
    bool? canDownload,
    String? supportLevel,
    List<String>? highlightedFeatures,
    double? price,
    String? description,
    String? interval,
  }) {
    return Plan(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      tier: tier ?? this.tier,
      priceCents: priceCents ?? this.priceCents,
      priceDisplay: priceDisplay ?? this.priceDisplay,
      billingInterval:
          clearBillingInterval ? null : billingInterval ?? this.billingInterval,
      uploadLimit: uploadLimit ?? this.uploadLimit,
      uploadLimitDisplay: uploadLimitDisplay ?? this.uploadLimitDisplay,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      trialDays: trialDays ?? this.trialDays,
      adsEnabled: adsEnabled ?? this.adsEnabled,
      canDownload: canDownload ?? this.canDownload,
      supportLevel: supportLevel ?? this.supportLevel,
      highlightedFeatures: highlightedFeatures ?? this.highlightedFeatures,
      price: price ?? this.price,
      description: description ?? this.description,
      interval: interval ?? this.interval,
    );
  }

  @override
  String toString() {
    return 'Plan(code: $code, name: $name, priceDisplay: $displayPrice)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Plan &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            code == other.code &&
            name == other.name &&
            tier == other.tier &&
            priceCents == other.priceCents &&
            priceDisplay == other.priceDisplay &&
            billingInterval == other.billingInterval &&
            uploadLimit == other.uploadLimit &&
            uploadLimitDisplay == other.uploadLimitDisplay &&
            isUnlimited == other.isUnlimited &&
            trialDays == other.trialDays &&
            adsEnabled == other.adsEnabled &&
            canDownload == other.canDownload &&
            supportLevel == other.supportLevel &&
            _listEquals(highlightedFeatures, other.highlightedFeatures) &&
            price == other.price &&
            description == other.description &&
            interval == other.interval;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      code,
      name,
      tier,
      priceCents,
      priceDisplay,
      billingInterval,
      uploadLimit,
      uploadLimitDisplay,
      isUnlimited,
      trialDays,
      adsEnabled,
      canDownload,
      supportLevel,
      Object.hashAll(highlightedFeatures),
      price,
      description,
      interval,
    );
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  final parsed = value?.toString().trim() ?? '';
  return parsed.isEmpty ? fallback : parsed;
}

String? _asNullableString(dynamic value) {
  final parsed = _asString(value);
  return parsed.isEmpty ? null : parsed;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _asDouble(dynamic value, {double fallback = 0.0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const <String>[];

  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _legacyInterval(String? billingInterval) {
  final normalized = billingInterval?.trim().toUpperCase() ?? '';

  switch (normalized) {
    case 'MONTHLY':
      return 'month';
    case 'YEARLY':
    case 'ANNUAL':
      return 'year';
    default:
      return normalized.toLowerCase();
  }
}

bool _listEquals(List<String> first, List<String> second) {
  if (identical(first, second)) return true;
  if (first.length != second.length) return false;

  for (int index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }

  return true;
}
