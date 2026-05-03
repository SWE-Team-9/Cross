class BillingPortalSession {
  final String url;
  final String portalUrl;
  final String sessionId;
  final String customerId;
  final String returnUrl;
  final DateTime? expiresAt;
  final String paymentMethodSummary;
  final Map<String, dynamic>? paymentMethod;
  final bool canUpdatePaymentMethod;
  final bool canCancel;
  final bool canResume;
  final bool canChangePlan;

  const BillingPortalSession({
    this.url = '',
    this.portalUrl = '',
    this.sessionId = '',
    this.customerId = '',
    this.returnUrl = '',
    this.expiresAt,
    this.paymentMethodSummary = '',
    this.paymentMethod,
    this.canUpdatePaymentMethod = false,
    this.canCancel = false,
    this.canResume = false,
    this.canChangePlan = false,
  });

  String get launchUrl {
    if (url.trim().isNotEmpty) {
      return url;
    }

    return portalUrl;
  }

  bool get hasLaunchUrl => launchUrl.trim().isNotEmpty;

  bool get hasPaymentMethod =>
      paymentMethodSummary.trim().isNotEmpty ||
      paymentMethod != null && paymentMethod!.isNotEmpty;

  bool get isExpired {
    final expiry = expiresAt;
    if (expiry == null) {
      return false;
    }

    return DateTime.now().toUtc().isAfter(expiry.toUtc());
  }

  factory BillingPortalSession.fromJson(Map<String, dynamic> json) {
    final capabilities = _asMap(
      json['capabilities'] ?? json['permissions'],
    );

    return BillingPortalSession(
      url: _asString(json['url']),
      portalUrl: _asString(json['portalUrl'] ?? json['portal_url']),
      sessionId: _asString(
        json['sessionId'] ?? json['session_id'] ?? json['id'],
      ),
      customerId: _asString(json['customerId'] ?? json['customer_id']),
      returnUrl: _asString(json['returnUrl'] ?? json['return_url']),
      expiresAt: _asDate(json['expiresAt'] ?? json['expires_at']),
      paymentMethodSummary: _asString(
        json['paymentMethodSummary'] ?? json['payment_method_summary'],
      ),
      paymentMethod: _asNullableMap(
        json['paymentMethod'] ?? json['payment_method'],
      ),
      canUpdatePaymentMethod: _asBool(
        json['canUpdatePaymentMethod'] ??
            json['can_update_payment_method'] ??
            capabilities['canUpdatePaymentMethod'] ??
            capabilities['can_update_payment_method'],
      ),
      canCancel: _asBool(
        json['canCancel'] ??
            json['can_cancel'] ??
            capabilities['canCancel'] ??
            capabilities['can_cancel'],
      ),
      canResume: _asBool(
        json['canResume'] ??
            json['can_resume'] ??
            capabilities['canResume'] ??
            capabilities['can_resume'],
      ),
      canChangePlan: _asBool(
        json['canChangePlan'] ??
            json['can_change_plan'] ??
            capabilities['canChangePlan'] ??
            capabilities['can_change_plan'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'url': url,
      'portalUrl': portalUrl,
      'sessionId': sessionId,
      'customerId': customerId,
      'returnUrl': returnUrl,
      'expiresAt': expiresAt?.toIso8601String(),
      'paymentMethodSummary': paymentMethodSummary,
      'paymentMethod': paymentMethod,
      'canUpdatePaymentMethod': canUpdatePaymentMethod,
      'canCancel': canCancel,
      'canResume': canResume,
      'canChangePlan': canChangePlan,
    };
  }

  BillingPortalSession copyWith({
    String? url,
    String? portalUrl,
    String? sessionId,
    String? customerId,
    String? returnUrl,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    String? paymentMethodSummary,
    Map<String, dynamic>? paymentMethod,
    bool clearPaymentMethod = false,
    bool? canUpdatePaymentMethod,
    bool? canCancel,
    bool? canResume,
    bool? canChangePlan,
  }) {
    return BillingPortalSession(
      url: url ?? this.url,
      portalUrl: portalUrl ?? this.portalUrl,
      sessionId: sessionId ?? this.sessionId,
      customerId: customerId ?? this.customerId,
      returnUrl: returnUrl ?? this.returnUrl,
      expiresAt: clearExpiresAt ? null : expiresAt ?? this.expiresAt,
      paymentMethodSummary: paymentMethodSummary ?? this.paymentMethodSummary,
      paymentMethod:
          clearPaymentMethod ? null : paymentMethod ?? this.paymentMethod,
      canUpdatePaymentMethod:
          canUpdatePaymentMethod ?? this.canUpdatePaymentMethod,
      canCancel: canCancel ?? this.canCancel,
      canResume: canResume ?? this.canResume,
      canChangePlan: canChangePlan ?? this.canChangePlan,
    );
  }

  @override
  String toString() {
    return 'BillingPortalSession(sessionId: $sessionId, hasLaunchUrl: '
        '$hasLaunchUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BillingPortalSession &&
            runtimeType == other.runtimeType &&
            url == other.url &&
            portalUrl == other.portalUrl &&
            sessionId == other.sessionId &&
            customerId == other.customerId &&
            returnUrl == other.returnUrl &&
            expiresAt == other.expiresAt &&
            paymentMethodSummary == other.paymentMethodSummary &&
            _mapEquals(paymentMethod, other.paymentMethod) &&
            canUpdatePaymentMethod == other.canUpdatePaymentMethod &&
            canCancel == other.canCancel &&
            canResume == other.canResume &&
            canChangePlan == other.canChangePlan;
  }

  @override
  int get hashCode {
    return Object.hash(
      url,
      portalUrl,
      sessionId,
      customerId,
      returnUrl,
      expiresAt,
      paymentMethodSummary,
      _mapHash(paymentMethod),
      canUpdatePaymentMethod,
      canCancel,
      canResume,
      canChangePlan,
    );
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  final parsed = value?.toString().trim() ?? '';
  return parsed.isEmpty ? fallback : parsed;
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

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

Map<String, dynamic>? _asNullableMap(dynamic value) {
  if (value == null) return null;

  final map = _asMap(value);
  return map.isEmpty ? null : map;
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
