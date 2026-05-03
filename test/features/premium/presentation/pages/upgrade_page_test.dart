import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:soundcloud_clone/features/premium/domain/entities/billing_invoice.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_portal_session.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/offline_track_entitlement.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/plan.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/pages/upgrade_page.dart';

void main() {
  const freeSubscription = Subscription(
    userId: 'user-1',
    planCode: 'FREE',
    subscriptionType: 'FREE',
    subscriptionStatus: 'ACTIVE',
    planName: 'Free',
    isPremium: false,
    adsEnabled: true,
    canDownload: false,
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
    uploadLimit: 100,
    uploadLimitDisplay: '100',
    uploadedTracks: 5,
    remainingUploads: 95,
    paymentMethodSummary: 'Visa •••• 4242',
  );

  const freePlan = Plan(
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
      'Ad-free listening',
      'Offline downloads',
      'Priority support',
    ],
  );

  tearDown(_resetTestView);

  group('UpgradePage', () {
    testWidgets('loads free subscription and renders upgrade plans',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: const <Plan>[freePlan, proPlan],
      );

      await _pumpUpgradePage(tester, repository);

      expect(find.text('Upgrade'), findsOneWidget);
      expect(find.text('Unlock IQA3 Premium'), findsOneWidget);
      expect(find.text('Current plan'), findsOneWidget);
      expect(find.text('Free'), findsWidgets);
      expect(find.text('Choose your plan'), findsOneWidget);
      expect(
        find.text(
          'Upgrade to unlock more uploads, ad-free listening, offline downloads, and priority support.',
        ),
        findsOneWidget,
      );
      expect(find.text('Upgrade to Pro'), findsOneWidget);
      expect(find.text('Manage billing'), findsNothing);

      expect(repository.getMySubscriptionCalls, 1);
      expect(repository.getPlansCalls, 1);
    });

    testWidgets('renders premium current plan and billing management button',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[freePlan, proPlan],
      );

      await _pumpUpgradePage(tester, repository);

      expect(find.text('You are on Pro'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('95 uploads remaining / 100'), findsOneWidget);
      expect(find.text('Ad-free listening'), findsWidgets);
      expect(find.text('Offline downloads unlocked'), findsOneWidget);
      expect(find.text('Manage billing'), findsOneWidget);
      expect(find.text('Current plan'), findsWidgets);
    });

    testWidgets(
        'manage billing navigates to billing route without opening portal',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[freePlan, proPlan],
      );

      await _pumpUpgradePage(tester, repository);

      await tester.tap(find.text('Manage billing'));
      await tester.pumpAndSettle();

      expect(find.text('Billing Route'), findsOneWidget);
      expect(repository.openBillingPortalSessionCalls, 0);
    });

    testWidgets('does not show manage billing for free users', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: const <Plan>[freePlan, proPlan],
      );

      await _pumpUpgradePage(tester, repository);

      expect(find.text('Manage billing'), findsNothing);
      expect(repository.openBillingPortalSessionCalls, 0);
    });

    testWidgets('refresh action reloads subscription and plans',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: const <Plan>[freePlan, proPlan],
      );

      await _pumpUpgradePage(tester, repository);

      expect(repository.getMySubscriptionCalls, 1);
      expect(repository.getPlansCalls, 1);

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(repository.getMySubscriptionCalls, 2);
      expect(repository.getPlansCalls, 2);
    });

    testWidgets('shows empty state when no plans are available',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
      );

      await _pumpUpgradePage(tester, repository);

      expect(
        find.text('No premium plans are available right now.'),
        findsOneWidget,
      );
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('empty state refresh retries loading plans', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
      );

      await _pumpUpgradePage(tester, repository);

      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();

      expect(repository.getMySubscriptionCalls, 2);
      expect(repository.getPlansCalls, 2);
    });

    testWidgets('shows error state when plans fail to load', (tester) async {
      final repository = _FakeSubscriptionRepository(
        loadError: Exception('Could not load premium data.'),
      );

      await _pumpUpgradePage(tester, repository);

      expect(find.text('Could not load premium data.'), findsWidgets);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('error retry reloads subscription and plans', (tester) async {
      final repository = _FakeSubscriptionRepository(
        loadError: Exception('Could not load premium data.'),
      );

      await _pumpUpgradePage(tester, repository);

      repository
        ..loadError = null
        ..subscription = freeSubscription
        ..plans = const <Plan>[freePlan, proPlan];

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(repository.getMySubscriptionCalls, 2);
      expect(repository.getPlansCalls, 2);
      expect(find.text('Upgrade to Pro'), findsOneWidget);
    });

    testWidgets('upgrade validates empty plan code', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: const <Plan>[
          Plan(
            code: '',
            name: 'Broken Plan',
            priceDisplay: r'$1.99/mo',
            uploadLimit: 10,
            uploadLimitDisplay: '10',
          ),
        ],
      );

      await _pumpUpgradePage(tester, repository);

      await tester.tap(find.text('Upgrade to Broken Plan'));
      await tester.pumpAndSettle();

      expect(
          find.text('This plan is not available right now.'), findsOneWidget);
      expect(repository.createCheckoutCalls, 0);
    });

    testWidgets('upgrade handles unavailable checkout link', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: const <Plan>[freePlan, proPlan],
        checkoutUrl: '',
      );

      await _pumpUpgradePage(tester, repository);

      await tester.tap(find.text('Upgrade to Pro'));
      await tester.pumpAndSettle();

      expect(repository.createCheckoutCalls, 1);
      expect(repository.lastCheckoutPlan, 'PRO');
      expect(repository.checkoutUrl, isEmpty);
    });
    testWidgets('upgrade rejects invalid checkout url value', (tester) async {
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
      expect(repository.checkoutUrl, 'not-a-valid-url');
    });
    testWidgets('upgrade error shows snackbar', (tester) async {
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

    testWidgets(
        'cancellation warning appears for canceling premium subscription',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription.copyWith(
          cancelAtPeriodEnd: true,
          canResume: true,
        ),
        plans: const <Plan>[freePlan, proPlan],
      );

      await _pumpUpgradePage(tester, repository);

      expect(
        find.text(
          'Your subscription is scheduled to cancel at the end of the current billing period.',
        ),
        findsOneWidget,
      );
    });
  });
}

Future<void> _pumpUpgradePage(
  WidgetTester tester,
  _FakeSubscriptionRepository repository,
) async {
  tester.view.physicalSize = const Size(1200, 2200);
  tester.view.devicePixelRatio = 1.0;

  final router = GoRouter(
    initialLocation: '/upgrade',
    routes: [
      GoRoute(
        path: '/upgrade',
        builder: (context, state) {
          return BlocProvider<SubscriptionCubit>(
            create: (_) => SubscriptionCubit(repository),
            child: const UpgradePage(),
          );
        },
      ),
      GoRoute(
        path: '/billing',
        builder: (context, state) {
          return const Scaffold(
            body: Center(
              child: Text('Billing Route'),
            ),
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
    ),
  );

  await tester.pumpAndSettle();
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
    this.checkoutUrl = 'not-a-valid-url',
    this.loadError,
    this.checkoutError,
  });

  Subscription subscription;
  List<Plan> plans;
  String checkoutUrl;
  Object? loadError;
  Object? checkoutError;

  int getMySubscriptionCalls = 0;
  int getPlansCalls = 0;
  int createCheckoutCalls = 0;
  int subscribeCalls = 0;
  int openBillingPortalSessionCalls = 0;
  int getInvoicesCalls = 0;
  int cancelSubscriptionCalls = 0;
  int resumeSubscriptionCalls = 0;
  int changePlanCalls = 0;
  int cancelPlanChangeCalls = 0;
  int getOfflineTrackEntitlementCalls = 0;
  String? lastCheckoutPlan;
  String? lastSubscribePlan;
  String? lastChangePlan;

  @override
  Future<Subscription> getMySubscription() async {
    getMySubscriptionCalls++;

    final error = loadError;
    if (error != null) {
      throw error;
    }

    return subscription;
  }

  @override
  Future<List<Plan>> getPlans() async {
    getPlansCalls++;

    final error = loadError;
    if (error != null) {
      throw error;
    }

    return plans;
  }

  @override
  Future<String> createCheckout(String plan) async {
    createCheckoutCalls++;
    lastCheckoutPlan = plan;

    final error = checkoutError;
    if (error != null) {
      throw error;
    }

    subscription = subscription.copyWith(
      planCode: plan,
      subscriptionType: plan,
      planName: plan == 'PRO' ? 'Pro' : plan,
      isPremium: plan.trim().toUpperCase() != 'FREE',
      adsEnabled: false,
      canDownload: true,
    );

    return checkoutUrl;
  }

  @override
  Future<String> subscribe(String plan) async {
    subscribeCalls++;
    lastSubscribePlan = plan;
    return 'https://subscribe.example.com/$plan';
  }

  @override
  Future<BillingPortalSession> openBillingPortalSession() async {
    openBillingPortalSessionCalls++;
    return const BillingPortalSession(
      url: 'https://billing.example.com/session/test',
      sessionId: 'bps_123',
    );
  }

  @override
  Future<List<BillingInvoice>> getInvoices() async {
    getInvoicesCalls++;
    return const <BillingInvoice>[];
  }

  @override
  Future<Subscription> cancelSubscription() async {
    cancelSubscriptionCalls++;
    subscription = subscription.copyWith(
      cancelAtPeriodEnd: true,
      canResume: true,
    );
    return subscription;
  }

  @override
  Future<Subscription> resumeSubscription() async {
    resumeSubscriptionCalls++;
    subscription = subscription.copyWith(
      cancelAtPeriodEnd: false,
      canResume: false,
    );
    return subscription;
  }

  @override
  Future<Subscription> changePlan(String plan) async {
    changePlanCalls++;
    lastChangePlan = plan;
    subscription = subscription.copyWith(
      planCode: plan,
      subscriptionType: plan,
      planName: plan,
      isPremium: plan.trim().toUpperCase() != 'FREE',
    );
    return subscription;
  }

  @override
  Future<Subscription> cancelPlanChange() async {
    subscription = subscription.copyWith(clearPendingDowngrade: true);

    return subscription;
  }

  @override
  Future<OfflineTrackEntitlement> getOfflineTrackEntitlement(
    String trackId,
  ) async {
    getOfflineTrackEntitlementCalls++;
    return OfflineTrackEntitlement(
      trackId: trackId,
      planCode: subscription.planCode,
    );
  }
}
