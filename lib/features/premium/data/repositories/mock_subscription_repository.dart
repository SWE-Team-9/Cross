import '../../domain/entities/billing_invoice.dart';
import '../../domain/entities/billing_portal_session.dart';
import '../../domain/entities/offline_track_entitlement.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  Subscription _current = const Subscription(
    userId: 'mock-user',
    planCode: 'FREE',
    subscriptionType: 'FREE',
    subscriptionStatus: 'ACTIVE',
    planName: 'Free',
    isPremium: false,
    adsEnabled: true,
    canDownload: false,
    supportLevel: 'community',
    uploadLimit: 3,
    uploadLimitDisplay: '3',
    uploadedTracks: 0,
    remainingUploads: 3,
  );

  final List<Plan> _plans = const <Plan>[
    Plan(
      id: 'mock-free',
      code: 'FREE',
      name: 'Free',
      tier: 'FREE',
      priceCents: 0,
      priceDisplay: 'Free',
      billingInterval: 'MONTHLY',
      uploadLimit: 3,
      uploadLimitDisplay: '3',
      adsEnabled: true,
      canDownload: false,
      supportLevel: 'community',
      highlightedFeatures: <String>[
        '3 uploads',
        'Standard streaming',
        'Ads supported',
      ],
      price: 0,
      description: 'Start listening and uploading with a limited free plan.',
      interval: 'month',
    ),
    Plan(
      id: 'mock-pro',
      code: 'PRO',
      name: 'Pro',
      tier: 'PRO',
      priceCents: 999,
      priceDisplay: r'$9.99/mo',
      billingInterval: 'MONTHLY',
      uploadLimit: 100,
      uploadLimitDisplay: '100',
      trialDays: 7,
      adsEnabled: false,
      canDownload: true,
      supportLevel: 'priority',
      highlightedFeatures: <String>[
        '100 uploads',
        'Ad-free listening',
        'Offline downloads',
        'Priority support',
      ],
      price: 9.99,
      description: 'More uploads, downloads, and ad-free listening.',
      interval: 'month',
    ),
    Plan(
      id: 'mock-go-plus',
      code: 'GO_PLUS',
      name: 'GO+',
      tier: 'GO_PLUS',
      priceCents: 1999,
      priceDisplay: r'$19.99/mo',
      billingInterval: 'MONTHLY',
      uploadLimit: 1000,
      uploadLimitDisplay: '1000',
      trialDays: 7,
      adsEnabled: false,
      canDownload: true,
      supportLevel: 'priority',
      highlightedFeatures: <String>[
        '1000 uploads',
        'Ad-free listening',
        'Offline downloads',
        'Priority support',
      ],
      price: 19.99,
      description: 'Maximum creator limits with premium listening features.',
      interval: 'month',
    ),
  ];

  final List<BillingInvoice> _invoices = const <BillingInvoice>[
    BillingInvoice(
      id: 'mock-invoice-1',
      invoiceId: 'in_mock_abc123',
      amountDueCents: 999,
      amountPaidCents: 999,
      currency: 'USD',
      status: 'PAID',
      planName: 'Pro',
      planTier: 'PRO',
    ),
  ];

  @override
  Future<Subscription> getMySubscription() async {
    return _current;
  }

  @override
  Future<List<Plan>> getPlans() async {
    return _plans;
  }

  @override
  Future<String> createCheckout(String plan) async {
    final normalizedPlan = plan.trim().toUpperCase();

    if (normalizedPlan.isEmpty || normalizedPlan == 'FREE') {
      return '';
    }

    _current = _subscriptionForPlan(normalizedPlan);

    return 'https://mock-checkout.example.com/$normalizedPlan';
  }

  @override
  Future<String> subscribe(String plan) async {
    final normalizedPlan = plan.trim().toUpperCase();

    if (normalizedPlan.isEmpty || normalizedPlan == 'FREE') {
      return '';
    }

    _current = _subscriptionForPlan(normalizedPlan);

    return 'https://mock-subscribe.example.com/$normalizedPlan';
  }

  @override
  Future<BillingPortalSession> openBillingPortalSession() async {
    return BillingPortalSession(
      url: 'https://mock-portal.example.com/session',
      portalUrl: 'https://mock-portal.example.com',
      sessionId: 'bps_mock_123',
      customerId: 'cus_mock_123',
      returnUrl: 'iqa3://billing/return',
      paymentMethodSummary:
          _current.isPremium ? 'Visa •••• 4242' : '',
      paymentMethod: _current.isPremium
          ? const <String, dynamic>{
              'brand': 'visa',
              'last4': '4242',
            }
          : null,
      canUpdatePaymentMethod: _current.isPremium,
      canCancel: _current.isPremium && !_current.cancelAtPeriodEnd,
      canResume: _current.canResume,
      canChangePlan: _current.isPremium,
    );
  }

  @override
  Future<String> openPortal() async {
    final session = await openBillingPortalSession();
    return session.launchUrl;
  }

  @override
  Future<List<BillingInvoice>> getInvoices() async {
    return _current.isPremium ? _invoices : const <BillingInvoice>[];
  }

  @override
  Future<Subscription> cancelSubscription() async {
    if (!_current.isPremium) {
      return _current;
    }

    _current = _current.copyWith(
      cancelAtPeriodEnd: true,
      canResume: true,
      subscriptionStatus: 'ACTIVE',
    );

    return _current;
  }

  @override
  Future<Subscription> resumeSubscription() async {
    if (!_current.isPremium) {
      return _current;
    }

    _current = _current.copyWith(
      cancelAtPeriodEnd: false,
      canResume: false,
      subscriptionStatus: 'ACTIVE',
    );

    return _current;
  }

  @override
  Future<Subscription> changePlan(String plan) async {
    final normalizedPlan = plan.trim().toUpperCase();

    if (normalizedPlan.isEmpty) {
      return _current;
    }

    _current = _subscriptionForPlan(normalizedPlan);

    return _current;
  }

  @override
  Future<OfflineTrackEntitlement> getOfflineTrackEntitlement(
    String trackId,
  ) async {
    final normalizedTrackId = trackId.trim();

    return OfflineTrackEntitlement(
      trackId: normalizedTrackId,
      title: 'Mock offline track',
      artist: 'IQA3 Artist',
      handle: 'iqa3artist',
      durationMs: 180000,
      coverArtUrl: 'https://mock-media.example.com/covers/$normalizedTrackId.jpg',
      downloadUrl:
          'https://mock-media.example.com/offline/$normalizedTrackId.mp3',
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 15)),
      expiresInSeconds: 900,
      offlineTokenId: 'offline_mock_$normalizedTrackId',
      planCode: _current.planCode,
    );
  }

  Subscription _subscriptionForPlan(String planCode) {
    switch (planCode) {
      case 'GO_PLUS':
        return const Subscription(
          userId: 'mock-user',
          planCode: 'GO_PLUS',
          subscriptionType: 'GO_PLUS',
          subscriptionStatus: 'ACTIVE',
          planName: 'GO+',
          isPremium: true,
          adsEnabled: false,
          canDownload: true,
          supportLevel: 'priority',
          uploadLimit: 1000,
          uploadLimitDisplay: '1000',
          uploadedTracks: 0,
          remainingUploads: 1000,
          paymentMethodSummary: 'Visa •••• 4242',
        );

      case 'PRO':
        return const Subscription(
          userId: 'mock-user',
          planCode: 'PRO',
          subscriptionType: 'PRO',
          subscriptionStatus: 'ACTIVE',
          planName: 'Pro',
          isPremium: true,
          adsEnabled: false,
          canDownload: true,
          supportLevel: 'priority',
          uploadLimit: 100,
          uploadLimitDisplay: '100',
          uploadedTracks: 0,
          remainingUploads: 100,
          paymentMethodSummary: 'Visa •••• 4242',
        );

      case 'FREE':
      default:
        return const Subscription(
          userId: 'mock-user',
          planCode: 'FREE',
          subscriptionType: 'FREE',
          subscriptionStatus: 'ACTIVE',
          planName: 'Free',
          isPremium: false,
          adsEnabled: true,
          canDownload: false,
          supportLevel: 'community',
          uploadLimit: 3,
          uploadLimitDisplay: '3',
          uploadedTracks: 0,
          remainingUploads: 3,
        );
    }
  }
}