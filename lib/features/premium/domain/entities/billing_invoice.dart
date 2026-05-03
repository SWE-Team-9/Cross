class BillingInvoice {
  final String id;
  final String invoiceId;
  final int amountDueCents;
  final int amountPaidCents;
  final String currency;
  final String status;
  final String planName;
  final String planTier;
  final DateTime? dueAt;
  final DateTime? paidAt;
  final DateTime? createdAt;

  const BillingInvoice({
    this.id = '',
    this.invoiceId = '',
    this.amountDueCents = 0,
    this.amountPaidCents = 0,
    this.currency = 'USD',
    this.status = '',
    this.planName = '',
    this.planTier = '',
    this.dueAt,
    this.paidAt,
    this.createdAt,
  });

  String get normalizedStatus => status.trim().toUpperCase();

  String get normalizedCurrency => currency.trim().toUpperCase();

  bool get isPaid => normalizedStatus == 'PAID';

  bool get isOpen => normalizedStatus == 'OPEN';

  bool get isFailed =>
      normalizedStatus == 'FAILED' ||
      normalizedStatus == 'UNCOLLECTIBLE' ||
      normalizedStatus == 'VOID';

  String get displayStatus {
    switch (normalizedStatus) {
      case 'PAID':
        return 'Paid';
      case 'OPEN':
        return 'Open';
      case 'DRAFT':
        return 'Draft';
      case 'VOID':
        return 'Void';
      case 'UNCOLLECTIBLE':
        return 'Uncollectible';
      case 'FAILED':
        return 'Failed';
      default:
        return normalizedStatus.isEmpty
            ? 'Unknown'
            : normalizedStatus[0] + normalizedStatus.substring(1).toLowerCase();
    }
  }

  String get displayAmountDue =>
      _formatMoney(amountDueCents, normalizedCurrency);

  String get displayAmountPaid =>
      _formatMoney(amountPaidCents, normalizedCurrency);

  String get displayPlanName {
    if (planName.trim().isNotEmpty) {
      return planName;
    }

    switch (planTier.trim().toUpperCase()) {
      case 'PRO':
        return 'Pro';
      case 'GO_PLUS':
        return 'GO+';
      case 'FREE':
        return 'Free';
      default:
        return planTier.trim();
    }
  }

  factory BillingInvoice.fromJson(Map<String, dynamic> json) {
    return BillingInvoice(
      id: _asString(json['id']),
      invoiceId: _asString(json['invoiceId'] ?? json['invoice_id']),
      amountDueCents: _asInt(
        json['amountDueCents'] ?? json['amount_due_cents'],
      ),
      amountPaidCents: _asInt(
        json['amountPaidCents'] ?? json['amount_paid_cents'],
      ),
      currency: _asString(json['currency'], fallback: 'USD').toUpperCase(),
      status: _asString(json['status']),
      planName: _asString(json['planName'] ?? json['plan_name']),
      planTier: _asString(json['planTier'] ?? json['plan_tier']),
      dueAt: _asDate(json['dueAt'] ?? json['due_at']),
      paidAt: _asDate(json['paidAt'] ?? json['paid_at']),
      createdAt: _asDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'invoiceId': invoiceId,
      'amountDueCents': amountDueCents,
      'amountPaidCents': amountPaidCents,
      'currency': currency,
      'status': status,
      'planName': planName,
      'planTier': planTier,
      'dueAt': dueAt?.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  BillingInvoice copyWith({
    String? id,
    String? invoiceId,
    int? amountDueCents,
    int? amountPaidCents,
    String? currency,
    String? status,
    String? planName,
    String? planTier,
    DateTime? dueAt,
    bool clearDueAt = false,
    DateTime? paidAt,
    bool clearPaidAt = false,
    DateTime? createdAt,
    bool clearCreatedAt = false,
  }) {
    return BillingInvoice(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      amountDueCents: amountDueCents ?? this.amountDueCents,
      amountPaidCents: amountPaidCents ?? this.amountPaidCents,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      planName: planName ?? this.planName,
      planTier: planTier ?? this.planTier,
      dueAt: clearDueAt ? null : dueAt ?? this.dueAt,
      paidAt: clearPaidAt ? null : paidAt ?? this.paidAt,
      createdAt: clearCreatedAt ? null : createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'BillingInvoice(invoiceId: $invoiceId, status: $status, '
        'amountPaidCents: $amountPaidCents)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BillingInvoice &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            invoiceId == other.invoiceId &&
            amountDueCents == other.amountDueCents &&
            amountPaidCents == other.amountPaidCents &&
            currency == other.currency &&
            status == other.status &&
            planName == other.planName &&
            planTier == other.planTier &&
            dueAt == other.dueAt &&
            paidAt == other.paidAt &&
            createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      invoiceId,
      amountDueCents,
      amountPaidCents,
      currency,
      status,
      planName,
      planTier,
      dueAt,
      paidAt,
      createdAt,
    );
  }
}

String _formatMoney(int cents, String currency) {
  final amount = cents / 100;
  final amountText = amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);

  switch (currency.toUpperCase()) {
    case 'USD':
      return '\$$amountText';
    case 'EUR':
      return '€$amountText';
    case 'GBP':
      return '£$amountText';
    default:
      return '$amountText ${currency.toUpperCase()}';
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  final parsed = value?.toString().trim() ?? '';
  return parsed.isEmpty ? fallback : parsed;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _asDate(dynamic value) {
  if (value is DateTime) return value;

  final parsed = value?.toString().trim() ?? '';
  if (parsed.isEmpty) return null;

  return DateTime.tryParse(parsed);
}
