class Subscription {
  final String userId;
  final String planCode;
  final String subscriptionType;
  final String subscriptionStatus;
  final String planName;
  final bool isPremium;
  final bool adsEnabled;
  final bool canDownload;
  final String supportLevel;
  final int uploadLimit;
  final String uploadLimitDisplay;
  final bool isUnlimited;
  final int uploadedTracks;
  final int remainingUploads;
  final DateTime? currentPeriodEnd;
  final DateTime? renewalDate;
  final DateTime? expiresAt;
  final bool cancelAtPeriodEnd;
  final bool canResume;
  final String? resumeBlockedReason;
  final String? resumeBlockedMessage;
  final DateTime? trialStart;
  final DateTime? trialEnd;
  final String? paymentMethodSummary;
  final Map<String, dynamic>? paymentMethod;
  final Map<String, dynamic>? pendingDowngrade;
  final Map<String, dynamic>? latestInvoice;

  const Subscription({
    this.userId = '',
    this.planCode = 'FREE',
    this.subscriptionType = 'FREE',
    this.subscriptionStatus = 'INACTIVE',
    this.planName = 'Free',
    this.isPremium = false,
    this.adsEnabled = true,
    this.canDownload = false,
    this.supportLevel = 'community',
    this.uploadLimit = 3,
    this.uploadLimitDisplay = '3',
    this.isUnlimited = false,
    this.uploadedTracks = 0,
    this.remainingUploads = 3,
    this.currentPeriodEnd,
    this.renewalDate,
    this.expiresAt,
    this.cancelAtPeriodEnd = false,
    this.canResume = false,
    this.resumeBlockedReason,
    this.resumeBlockedMessage,
    this.trialStart,
    this.trialEnd,
    this.paymentMethodSummary,
    this.paymentMethod,
    this.pendingDowngrade,
    this.latestInvoice,
  });

  String get normalizedPlanCode => planCode.trim().toUpperCase();

  String get normalizedSubscriptionType =>
      subscriptionType.trim().toUpperCase();

  String get normalizedStatus => subscriptionStatus.trim().toUpperCase();

  bool get isFree => normalizedPlanCode == 'FREE' && !isPremium;

  /// Legacy getter kept for upload feature callers.
  ///
  /// In the older code this meant "not FREE", not strictly the PRO plan.
  bool get isPro => isPremium || normalizedSubscriptionType != 'FREE';

  bool get isProPlan =>
      normalizedPlanCode == 'PRO' || normalizedSubscriptionType == 'PRO';

  bool get isGoPlus =>
      normalizedPlanCode == 'GO_PLUS' ||
      normalizedSubscriptionType == 'GO_PLUS';

  bool get isActive =>
      normalizedStatus == 'ACTIVE' ||
      normalizedStatus == 'TRIALING' ||
      normalizedStatus == 'PAST_DUE';

  bool get isTrialing => normalizedStatus == 'TRIALING';

  bool get isCanceled =>
      normalizedStatus == 'CANCELED' || normalizedStatus == 'CANCELLED';

  bool get hasPaymentMethod =>
      paymentMethodSummary != null && paymentMethodSummary!.trim().isNotEmpty;

  bool get hasPendingDowngrade =>
      pendingDowngrade != null && pendingDowngrade!.isNotEmpty;

  bool get hasLatestInvoice =>
      latestInvoice != null && latestInvoice!.isNotEmpty;

  bool get hasRemainingUploads => isUnlimited || remainingUploads > 0;

  bool get canUpload => isActive && hasRemainingUploads;

  bool get shouldShowAds => adsEnabled;

  bool get shouldShowUpgradePrompt => !isPremium;

  String get displayPlanName {
    if (planName.trim().isNotEmpty) {
      return planName;
    }

    if (isGoPlus) {
      return 'GO+';
    }

    if (isProPlan) {
      return 'Pro';
    }

    return 'Free';
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

  String get displayRemainingUploads {
    if (isUnlimited) {
      return 'Unlimited';
    }

    return remainingUploads.toString();
  }

  double get uploadUsageRatio {
    if (isUnlimited || uploadLimit <= 0) {
      return 0;
    }

    final ratio = uploadedTracks / uploadLimit;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  DateTime? get nextBillingDate => renewalDate ?? currentPeriodEnd;

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final String parsedPlanCode = _asString(
      json['planCode'] ?? json['plan_code'],
      fallback: _asString(
        json['subscriptionType'] ?? json['subscription_type'],
        fallback: 'FREE',
      ),
    );
    final String parsedSubscriptionType = _asString(
      json['subscriptionType'] ?? json['subscription_type'],
      fallback: parsedPlanCode.isEmpty ? 'FREE' : parsedPlanCode,
    );

    final String parsedStatus = _asString(
      json['subscriptionStatus'] ?? json['subscription_status'],
      fallback: 'INACTIVE',
    );

    final bool parsedIsPremium = _asBool(
      json['isPremium'] ?? json['is_premium'],
      fallback: parsedPlanCode.trim().toUpperCase() != 'FREE' ||
          parsedSubscriptionType.trim().toUpperCase() != 'FREE',
    );

    final int parsedUploadLimit = _asInt(
      json['uploadLimit'] ?? json['upload_limit'],
      fallback: parsedIsPremium ? 100 : 3,
    );

    final int parsedUploadedTracks = _asInt(
      json['uploadedTracks'] ?? json['uploaded_tracks'],
    );

    final int parsedRemainingUploads = _asInt(
      json['remainingUploads'] ?? json['remaining_uploads'],
      fallback: parsedUploadLimit - parsedUploadedTracks,
    );

    final bool parsedIsUnlimited = _asBool(
      json['isUnlimited'] ?? json['is_unlimited'],
    );

    return Subscription(
      userId: _asString(json['userId'] ?? json['user_id']),
      planCode: parsedPlanCode.isEmpty ? 'FREE' : parsedPlanCode,
      subscriptionType:
          parsedSubscriptionType.isEmpty ? 'FREE' : parsedSubscriptionType,
      subscriptionStatus: parsedStatus,
      planName: _asString(
        json['planName'] ?? json['plan_name'],
        fallback: _fallbackPlanName(parsedPlanCode),
      ),
      isPremium: parsedIsPremium,
      adsEnabled: _asBool(
        json['adsEnabled'] ?? json['ads_enabled'],
        fallback: !parsedIsPremium,
      ),
      canDownload: _asBool(json['canDownload'] ?? json['can_download']),
      supportLevel: _asString(
        json['supportLevel'] ?? json['support_level'],
        fallback: parsedIsPremium ? 'priority' : 'community',
      ),
      uploadLimit: parsedUploadLimit,
      uploadLimitDisplay: _asString(
        json['uploadLimitDisplay'] ?? json['upload_limit_display'],
        fallback:
            parsedIsUnlimited ? 'Unlimited' : parsedUploadLimit.toString(),
      ),
      isUnlimited: parsedIsUnlimited,
      uploadedTracks: parsedUploadedTracks,
      remainingUploads: parsedRemainingUploads < 0 ? 0 : parsedRemainingUploads,
      currentPeriodEnd: _asDate(
        json['currentPeriodEnd'] ?? json['current_period_end'],
      ),
      renewalDate: _asDate(json['renewalDate'] ?? json['renewal_date']),
      expiresAt: _asDate(json['expiresAt'] ?? json['expires_at']),
      cancelAtPeriodEnd: _asBool(
        json['cancelAtPeriodEnd'] ?? json['cancel_at_period_end'],
      ),
      canResume: _asBool(json['canResume'] ?? json['can_resume']),
      resumeBlockedReason: _asNullableString(
        json['resumeBlockedReason'] ?? json['resume_blocked_reason'],
      ),
      resumeBlockedMessage: _asNullableString(
        json['resumeBlockedMessage'] ?? json['resume_blocked_message'],
      ),
      trialStart: _asDate(json['trialStart'] ?? json['trial_start']),
      trialEnd: _asDate(json['trialEnd'] ?? json['trial_end']),
      paymentMethodSummary: _asNullableString(
        json['paymentMethodSummary'] ?? json['payment_method_summary'],
      ),
      paymentMethod: _asNullableMap(
        json['paymentMethod'] ?? json['payment_method'],
      ),
      pendingDowngrade: _asNullableMap(
        json['pendingDowngrade'] ?? json['pending_downgrade'],
      ),
      latestInvoice: _asNullableMap(
        json['latestInvoice'] ?? json['latest_invoice'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'planCode': planCode,
      'subscriptionType': subscriptionType,
      'subscriptionStatus': subscriptionStatus,
      'planName': planName,
      'isPremium': isPremium,
      'adsEnabled': adsEnabled,
      'canDownload': canDownload,
      'supportLevel': supportLevel,
      'uploadLimit': uploadLimit,
      'uploadLimitDisplay': uploadLimitDisplay,
      'isUnlimited': isUnlimited,
      'uploadedTracks': uploadedTracks,
      'remainingUploads': remainingUploads,
      'currentPeriodEnd': currentPeriodEnd?.toIso8601String(),
      'renewalDate': renewalDate?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'cancelAtPeriodEnd': cancelAtPeriodEnd,
      'canResume': canResume,
      'resumeBlockedReason': resumeBlockedReason,
      'resumeBlockedMessage': resumeBlockedMessage,
      'trialStart': trialStart?.toIso8601String(),
      'trialEnd': trialEnd?.toIso8601String(),
      'paymentMethodSummary': paymentMethodSummary,
      'paymentMethod': paymentMethod,
      'pendingDowngrade': pendingDowngrade,
      'latestInvoice': latestInvoice,
    };
  }

  Subscription copyWith({
    String? userId,
    String? planCode,
    String? subscriptionType,
    String? subscriptionStatus,
    String? planName,
    bool? isPremium,
    bool? adsEnabled,
    bool? canDownload,
    String? supportLevel,
    int? uploadLimit,
    String? uploadLimitDisplay,
    bool? isUnlimited,
    int? uploadedTracks,
    int? remainingUploads,
    DateTime? currentPeriodEnd,
    bool clearCurrentPeriodEnd = false,
    DateTime? renewalDate,
    bool clearRenewalDate = false,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    bool? cancelAtPeriodEnd,
    bool? canResume,
    String? resumeBlockedReason,
    bool clearResumeBlockedReason = false,
    String? resumeBlockedMessage,
    bool clearResumeBlockedMessage = false,
    DateTime? trialStart,
    bool clearTrialStart = false,
    DateTime? trialEnd,
    bool clearTrialEnd = false,
    String? paymentMethodSummary,
    bool clearPaymentMethodSummary = false,
    Map<String, dynamic>? paymentMethod,
    bool clearPaymentMethod = false,
    Map<String, dynamic>? pendingDowngrade,
    bool clearPendingDowngrade = false,
    Map<String, dynamic>? latestInvoice,
    bool clearLatestInvoice = false,
  }) {
    return Subscription(
      userId: userId ?? this.userId,
      planCode: planCode ?? this.planCode,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      planName: planName ?? this.planName,
      isPremium: isPremium ?? this.isPremium,
      adsEnabled: adsEnabled ?? this.adsEnabled,
      canDownload: canDownload ?? this.canDownload,
      supportLevel: supportLevel ?? this.supportLevel,
      uploadLimit: uploadLimit ?? this.uploadLimit,
      uploadLimitDisplay: uploadLimitDisplay ?? this.uploadLimitDisplay,
      isUnlimited: isUnlimited ?? this.isUnlimited,
      uploadedTracks: uploadedTracks ?? this.uploadedTracks,
      remainingUploads: remainingUploads ?? this.remainingUploads,
      currentPeriodEnd: clearCurrentPeriodEnd
          ? null
          : currentPeriodEnd ?? this.currentPeriodEnd,
      renewalDate: clearRenewalDate ? null : renewalDate ?? this.renewalDate,
      expiresAt: clearExpiresAt ? null : expiresAt ?? this.expiresAt,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      canResume: canResume ?? this.canResume,
      resumeBlockedReason: clearResumeBlockedReason
          ? null
          : resumeBlockedReason ?? this.resumeBlockedReason,
      resumeBlockedMessage: clearResumeBlockedMessage
          ? null
          : resumeBlockedMessage ?? this.resumeBlockedMessage,
      trialStart: clearTrialStart ? null : trialStart ?? this.trialStart,
      trialEnd: clearTrialEnd ? null : trialEnd ?? this.trialEnd,
      paymentMethodSummary: clearPaymentMethodSummary
          ? null
          : paymentMethodSummary ?? this.paymentMethodSummary,
      paymentMethod:
          clearPaymentMethod ? null : paymentMethod ?? this.paymentMethod,
      pendingDowngrade: clearPendingDowngrade
          ? null
          : pendingDowngrade ?? this.pendingDowngrade,
      latestInvoice:
          clearLatestInvoice ? null : latestInvoice ?? this.latestInvoice,
    );
  }

  @override
  String toString() {
    return 'Subscription(planCode: $planCode, status: $subscriptionStatus, '
        'isPremium: $isPremium)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Subscription &&
            runtimeType == other.runtimeType &&
            userId == other.userId &&
            planCode == other.planCode &&
            subscriptionType == other.subscriptionType &&
            subscriptionStatus == other.subscriptionStatus &&
            planName == other.planName &&
            isPremium == other.isPremium &&
            adsEnabled == other.adsEnabled &&
            canDownload == other.canDownload &&
            supportLevel == other.supportLevel &&
            uploadLimit == other.uploadLimit &&
            uploadLimitDisplay == other.uploadLimitDisplay &&
            isUnlimited == other.isUnlimited &&
            uploadedTracks == other.uploadedTracks &&
            remainingUploads == other.remainingUploads &&
            currentPeriodEnd == other.currentPeriodEnd &&
            renewalDate == other.renewalDate &&
            expiresAt == other.expiresAt &&
            cancelAtPeriodEnd == other.cancelAtPeriodEnd &&
            canResume == other.canResume &&
            resumeBlockedReason == other.resumeBlockedReason &&
            resumeBlockedMessage == other.resumeBlockedMessage &&
            trialStart == other.trialStart &&
            trialEnd == other.trialEnd &&
            paymentMethodSummary == other.paymentMethodSummary &&
            _mapEquals(paymentMethod, other.paymentMethod) &&
            _mapEquals(pendingDowngrade, other.pendingDowngrade) &&
            _mapEquals(latestInvoice, other.latestInvoice);
  }

  @override
  int get hashCode {
    return Object.hashAll(<Object?>[
      userId,
      planCode,
      subscriptionType,
      subscriptionStatus,
      planName,
      isPremium,
      adsEnabled,
      canDownload,
      supportLevel,
      uploadLimit,
      uploadLimitDisplay,
      isUnlimited,
      uploadedTracks,
      remainingUploads,
      currentPeriodEnd,
      renewalDate,
      expiresAt,
      cancelAtPeriodEnd,
      canResume,
      resumeBlockedReason,
      resumeBlockedMessage,
      trialStart,
      trialEnd,
      paymentMethodSummary,
      _mapHash(paymentMethod),
      _mapHash(pendingDowngrade),
      _mapHash(latestInvoice),
    ]);
  }
}

String _fallbackPlanName(String planCode) {
  switch (planCode.trim().toUpperCase()) {
    case 'PRO':
      return 'Pro';
    case 'GO_PLUS':
      return 'GO+';
    default:
      return 'Free';
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

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;

  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;

  return fallback;
}

DateTime? _asDate(dynamic value) {
  if (value is DateTime) return value;

  final parsed = value?.toString().trim() ?? '';
  if (parsed.isEmpty) return null;

  return DateTime.tryParse(parsed);
}

Map<String, dynamic>? _asNullableMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
  if (value is Map) return Map<String, dynamic>.from(value);

  return null;
}

bool _mapEquals(Map<String, dynamic>? first, Map<String, dynamic>? second) {
  if (identical(first, second)) return true;
  if (first == null || second == null) return false;
  if (first.length != second.length) return false;

  for (final key in first.keys) {
    if (!second.containsKey(key)) return false;

    final firstValue = first[key];
    final secondValue = second[key];

    if (firstValue is Map && secondValue is Map) {
      if (!_mapEquals(
        Map<String, dynamic>.from(firstValue),
        Map<String, dynamic>.from(secondValue),
      )) {
        return false;
      }
      continue;
    }

    if (firstValue != secondValue) return false;
  }

  return true;
}

int _mapHash(Map<String, dynamic>? value) {
  if (value == null) return 0;

  final keys = value.keys.toList(growable: false)..sort();

  return Object.hashAll(
    keys.map((key) {
      final item = value[key];

      if (item is Map) {
        return Object.hash(key, _mapHash(Map<String, dynamic>.from(item)));
      }

      return Object.hash(key, item);
    }),
  );
}
