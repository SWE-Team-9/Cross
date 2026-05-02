import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/features/premium/domain/entities/billing_invoice.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_portal_session.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/offline_track_entitlement.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/plan.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/pages/upgrade_page.dart';

void main() {
  const freePlan = Plan(
    code: 'FREE',
    name: 'Free',
    tier: 'FREE',
    priceCents: 0,
    priceDisplay: 'Free',
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
  );

  const proPlan = Plan(
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
      'Ad-free',
      'Downloads',
      'Priority support',
    ],
  );

  const goPlusPlan = Plan(
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
      'Ad-free',
      'Downloads',
      'Priority support',
    ],
  );

  const freeSubscription = Subscription(
    userId: 'user-1',
    planCode: 'FREE',
    subscriptionType: 'FREE',
    subscriptionStatus: 'INACTIVE',
    planName: 'Free',
    isPremium: false,
    adsEnabled: true,
    canDownload: false,
    supportLevel: 'community',
    uploadLimit: 3,
    uploadLimitDisplay: '3',
    uploadedTracks: 3,
    remainingUploads: 0,
  );

  const proSubscription = Subscription(
    userId: 'user-1',
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
    uploadedTracks: 5,
    remainingUploads: 95,
  );

  const cancelingSubscription = Subscription(
    userId: 'user-1',
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
    uploadedTracks: 5,
    remainingUploads: 95,
    cancelAtPeriodEnd: true,
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() {
    _resetTestView();
  });

  group('UpgradePage', () {
    testWidgets('loads subscription and renders premium plans for free users',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: const <Plan>[freePlan, proPlan, goPlusPlan],
      );

      await _pumpUpgradePage(tester, repository);

      expect(find.text('Upgrade'), findsOneWidget);
      expect(find.text('Unlock IQA3 Premium'), findsOneWidget);
      expect(find.text('Current plan'), findsOneWidget);
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Choose your plan'), findsOneWidget);
      expect(find.text('Pro'), findsWidgets);
      expect(find.text('GO+'), findsWidgets);
      expect(find.text(r'$9.99/mo'), findsOneWidget);
      expect(find.text(r'$19.99/mo'), findsOneWidget);
      expect(find.text('100 uploads'), findsWidgets);
      expect(find.text('1000 uploads'), findsWidgets);
      expect(find.text('Ad-free listening'), findsWidgets);
      expect(find.text('Offline downloads'), findsWidgets);
      expect(find.text('Upgrade to Pro'), findsOneWidget);
      expect(find.text('Upgrade to GO+'), findsOneWidget);

      expect(repository.getMySubscriptionCalls, 1);
      expect(repository.getPlansCalls, 1);
    });

    testWidgets('renders current premium plan and manage billing button',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[freePlan, proPlan, goPlusPlan],
      );

      await _pumpUpgradePage(tester, repository);

      expect(find.text('You are on Pro'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('95 uploads remaining / 100'), findsOneWidget);
      expect(find.text('Ad-free listening'), findsWidgets);
      expect(find.text('Offline downloads unlocked'), findsOneWidget);
      expect(find.text('Manage billing'), findsOneWidget);
      expect(find.text('Current plan'), findsWidgets);
      expect(find.text('Upgrade to GO+'), findsOneWidget);
    });

    testWidgets('shows cancellation warning for cancel-at-period-end subscription',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: cancelingSubscription,
        plans: const <Plan>[freePlan, proPlan, goPlusPlan],
      );

      await _pumpUpgradePage(tester, repository);

      expect(
        find.text(
          'Your subscription is scheduled to cancel at the end of the current billing period.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows loading indicator while subscription is loading',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: const <Plan>[freePlan, proPlan],
        responseDelay: const Duration(milliseconds: 300),
      );

      await _pumpUpgradePage(
        tester,
        repository,
        settle: false,
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.pumpAndSettle();
    });

    testWidgets('shows error state and snackbar when loading fails',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        loadError: Exception('Failed to load subscription.'),
      );

      await _pumpUpgradePage(tester, repository);

      expect(find.text('Failed to load subscription.'), findsWidgets);
      expect(find.text('Try again'), findsOneWidget);
      expect(repository.getMySubscriptionCalls, 1);
    });

    testWidgets('retry button reloads data after a failure', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: const <Plan>[freePlan, proPlan],
        failFirstLoad: true,
      );

      await _pumpUpgradePage(tester, repository);

      expect(find.text('First load failed.'), findsWidgets);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Unlock IQA3 Premium'), findsOneWidget);
      expect(find.text('Pro'), findsWidgets);
      expect(repository.getMySubscriptionCalls, 2);
      expect(repository.getPlansCalls, 2);
    });

    testWidgets('refresh action calls loadSubscription again', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: const <Plan>[freePlan, proPlan],
      );

      await _pumpUpgradePage(tester, repository);

      expect(repository.getMySubscriptionCalls, 1);

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(repository.getMySubscriptionCalls, 2);
      expect(repository.getPlansCalls, 2);
    });

    testWidgets('shows empty state when no plans are available', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: const <Plan>[],
      );

      await _pumpUpgradePage(tester, repository);

      expect(
        find.text('No premium plans are available right now.'),
        findsOneWidget,
      );
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('refresh indicator reloads subscription', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: const <Plan>[freePlan, proPlan],
      );

      await _pumpUpgradePage(tester, repository);

      expect(repository.getMySubscriptionCalls, 1);

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(repository.getMySubscriptionCalls, greaterThanOrEqualTo(2));
    });

    testWidgets('tapping upgrade creates checkout url and shows success snackbar',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: const <Plan>[freePlan, proPlan],
        checkoutUrl: 'not-a-valid-url',
      );

      await _pumpUpgradePage(tester, repository);

      await tester.tap(find.text('Upgrade to Pro'));
      await tester.pumpAndSettle();

      expect(repository.createCheckoutCalls, 1);
      expect(repository.lastCheckoutPlan, 'PRO');
      expect(find.text('Checkout session created.'), findsOneWidget);
      expect(
        find.text('Invalid link returned from the server.'),
        findsOneWidget,
      );
    });

    testWidgets('shows checkout error when upgrade fails', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: const <Plan>[freePlan, proPlan],
        checkoutError: Exception('Checkout failed.'),
      );

      await _pumpUpgradePage(tester, repository);

      await tester.tap(find.text('Upgrade to Pro'));
      await tester.pumpAndSettle();

      expect(repository.createCheckoutCalls, 1);
      expect(find.text('Checkout failed.'), findsOneWidget);
    });

    testWidgets('tapping manage billing creates portal session', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[freePlan, proPlan],
        portalSession: const BillingPortalSession(
          url: 'not-a-valid-url',
          sessionId: 'bps_123',
        ),
      );

      await _pumpUpgradePage(tester, repository);

      await tester.tap(find.text('Manage billing'));
      await tester.pumpAndSettle();

      expect(repository.openBillingPortalSessionCalls, 1);
      expect(find.text('Billing portal opened.'), findsOneWidget);
      expect(
        find.text('Invalid link returned from the server.'),
        findsOneWidget,
      );
    });

    testWidgets('shows billing portal error when portal creation fails',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[freePlan, proPlan],
        portalError: Exception('Portal failed.'),
      );

      await _pumpUpgradePage(tester, repository);

      await tester.tap(find.text('Manage billing'));
      await tester.pumpAndSettle();

      expect(repository.openBillingPortalSessionCalls, 1);
      expect(find.text('Portal failed.'), findsOneWidget);
    });
  });
}

Future<void> _pumpUpgradePage(
  WidgetTester tester,
  _FakeSubscriptionRepository repository, {
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<SubscriptionCubit>(
        create: (_) => SubscriptionCubit(repository),
        child: const UpgradePage(),
      ),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  }
}

void _resetTestView() {
  final binding = TestWidgetsFlutterBinding.instance;
  binding.platformDispatcher.views.first.resetPhysicalSize();
  binding.platformDispatcher.views.first.resetDevicePixelRatio();
}

class _FakeSubscriptionRepository extends SubscriptionRepository {
  _FakeSubscriptionRepository({
    this.subscription = const Subscription(),
    this.plans = const <Plan>[],
    this.invoices = const <BillingInvoice>[],
    this.checkoutUrl = 'https://checkout.example.com/pro',
    this.portalSession = const BillingPortalSession(
      url: 'https://billing.example.com/session/test',
      sessionId: 'bps_123',
    ),
    this.loadError,
    this.checkoutError,
    this.portalError,
    this.failFirstLoad = false,
    this.responseDelay = Duration.zero,
  });

  final Subscription subscription;
  final List<Plan> plans;
  final List<BillingInvoice> invoices;
  final String checkoutUrl;
  final BillingPortalSession portalSession;
  final Exception? loadError;
  final Exception? checkoutError;
  final Exception? portalError;
  final bool failFirstLoad;
  final Duration responseDelay;

  int getMySubscriptionCalls = 0;
  int getPlansCalls = 0;
  int createCheckoutCalls = 0;
  int subscribeCalls = 0;
  int openBillingPortalSessionCalls = 0;
  int getInvoicesCalls = 0;
  int cancelSubscriptionCalls = 0;
  int resumeSubscriptionCalls = 0;
  int changePlanCalls = 0;
  int getOfflineTrackEntitlementCalls = 0;

  String? lastCheckoutPlan;
  String? lastSubscribePlan;
  String? lastChangePlan;
  String? lastOfflineTrackId;

  Future<void> _delayIfNeeded() async {
    if (responseDelay == Duration.zero) {
      return;
    }

    await Future<void>.delayed(responseDelay);
  }

  @override
  Future<Subscription> getMySubscription() async {
    getMySubscriptionCalls++;
    await _delayIfNeeded();

    if (loadError != null) {
      throw loadError!;
    }

    if (failFirstLoad && getMySubscriptionCalls == 1) {
      throw Exception('First load failed.');
    }

    return subscription;
  }

  @override
  Future<List<Plan>> getPlans() async {
    getPlansCalls++;
    await _delayIfNeeded();

    if (loadError != null) {
      throw loadError!;
    }

    if (failFirstLoad && getPlansCalls == 1) {
      throw Exception('First load failed.');
    }

    return plans;
  }

  @override
  Future<String> createCheckout(String plan) async {
    createCheckoutCalls++;
    lastCheckoutPlan = plan;

    if (checkoutError != null) {
      throw checkoutError!;
    }

    return checkoutUrl;
  }

  @override
  Future<String> subscribe(String plan) async {
    subscribeCalls++;
    lastSubscribePlan = plan;
    return checkoutUrl;
  }

  @override
  Future<BillingPortalSession> openBillingPortalSession() async {
    openBillingPortalSessionCalls++;

    if (portalError != null) {
      throw portalError!;
    }

    return portalSession;
  }

  @override
  Future<List<BillingInvoice>> getInvoices() async {
    getInvoicesCalls++;
    return invoices;
  }

  @override
  Future<Subscription> cancelSubscription() async {
    cancelSubscriptionCalls++;
    return subscription.copyWith(
      cancelAtPeriodEnd: true,
      canResume: true,
    );
  }

  @override
  Future<Subscription> resumeSubscription() async {
    resumeSubscriptionCalls++;
    return subscription.copyWith(
      cancelAtPeriodEnd: false,
      canResume: false,
    );
  }

  @override
  Future<Subscription> changePlan(String plan) async {
    changePlanCalls++;
    lastChangePlan = plan;

    return subscription.copyWith(
      planCode: plan,
      subscriptionType: plan,
      isPremium: plan.trim().toUpperCase() != 'FREE',
    );
  }

  @override
  Future<OfflineTrackEntitlement> getOfflineTrackEntitlement(
    String trackId,
  ) async {
    getOfflineTrackEntitlementCalls++;
    lastOfflineTrackId = trackId;

    return OfflineTrackEntitlement(
      trackId: trackId,
      planCode: subscription.planCode,
    );
  }
}