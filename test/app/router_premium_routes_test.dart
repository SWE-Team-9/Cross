import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:soundcloud_clone/app/router.dart';
import 'package:soundcloud_clone/core/deep_links/deep_link_destination.dart';
import 'package:soundcloud_clone/core/deep_links/deep_link_service.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_invoice.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_portal_session.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/offline_track_entitlement.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/plan.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/pages/billing_page.dart';
import 'package:soundcloud_clone/features/premium/presentation/pages/upgrade_page.dart';

void main() {
  late _FakeSubscriptionRepository subscriptionRepository;

  setUp(() async {
    await GetIt.I.reset();

    subscriptionRepository = _FakeSubscriptionRepository();

    GetIt.I.registerSingleton<DeepLinkService>(
      _FakeDeepLinkService(),
    );

    GetIt.I.registerSingleton<SubscriptionRepository>(
      subscriptionRepository,
    );

    GetIt.I.registerSingleton<SubscriptionCubit>(
      SubscriptionCubit(subscriptionRepository),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('premium router routes', () {
    testWidgets('AppRoutes exposes upgrade and billing paths', (tester) async {
      expect(AppRoutes.upgrade, '/upgrade');
      expect(AppRoutes.billing, '/billing');
    });

    testWidgets('navigates to upgrade page', (tester) async {
      await _pumpRoute(
        tester,
        initialLocation: AppRoutes.upgrade,
        subscriptionRepository: subscriptionRepository,
      );

      expect(find.byType(UpgradePage), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
      expect(find.text('Unlock IQA3 Premium'), findsOneWidget);
      expect(find.text('Choose your plan'), findsOneWidget);
      expect(find.text('Upgrade to Pro'), findsOneWidget);

      expect(subscriptionRepository.getMySubscriptionCalls, 1);
      expect(subscriptionRepository.getPlansCalls, 1);
    });

    testWidgets('navigates to billing page', (tester) async {
      await _pumpRoute(
        tester,
        initialLocation: AppRoutes.billing,
        subscriptionRepository: subscriptionRepository,
      );

      expect(find.byType(BillingPage), findsOneWidget);
      expect(find.text('Billing'), findsOneWidget);
      expect(find.text('Subscription'), findsOneWidget);
      expect(find.text('Invoices'), findsOneWidget);

      expect(subscriptionRepository.getMySubscriptionCalls, greaterThanOrEqualTo(1));
      expect(subscriptionRepository.getInvoicesCalls, 1);
    });

    testWidgets('unknown route still shows fallback page', (tester) async {
      await _pumpRoute(
        tester,
        initialLocation: '/missing-premium-route',
        subscriptionRepository: subscriptionRepository,
      );

      expect(find.text('Page not found'), findsOneWidget);
      expect(find.text('Go Home'), findsOneWidget);
    });
  });
}

Future<void> _pumpRoute(
  WidgetTester tester, {
  required String initialLocation,
  required _FakeSubscriptionRepository subscriptionRepository,
}) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final router = createRouter()..go(initialLocation);

  await tester.pumpWidget(
    BlocProvider<SubscriptionCubit>.value(
      value: GetIt.I<SubscriptionCubit>(),
      child: MaterialApp.router(
        routerConfig: router,
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

class _FakeDeepLinkService implements DeepLinkService {
  @override
  Stream<DeepLinkDestination> get stream => const Stream.empty();

  @override
  DeepLinkDestination? consumeLastDestination() => null;

  @override
  DeepLinkDestination? peekLastDestination() => null;

  @override
  void markLastDestinationConsumed() {}

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {}
}

class _FakeSubscriptionRepository extends SubscriptionRepository {
  final Subscription subscription = const Subscription(
    userId: 'user-1',
    planCode: 'FREE',
    subscriptionType: 'FREE',
    subscriptionStatus: 'INACTIVE',
    planName: 'Free',
    isPremium: false,
    adsEnabled: true,
    canDownload: false,
    uploadLimit: 3,
    uploadLimitDisplay: '3',
    uploadedTracks: 3,
    remainingUploads: 0,
  );

  final List<Plan> plans = const <Plan>[
    Plan(
      code: 'FREE',
      name: 'Free',
      tier: 'FREE',
      priceCents: 0,
      priceDisplay: 'Free',
      uploadLimit: 3,
      uploadLimitDisplay: '3',
      adsEnabled: true,
      canDownload: false,
    ),
    Plan(
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
    ),
  ];

  final List<BillingInvoice> invoices = const <BillingInvoice>[
    BillingInvoice(
      invoiceId: 'in_mock_abc123',
      amountPaidCents: 999,
      currency: 'USD',
      status: 'PAID',
      planName: 'Pro',
      planTier: 'PRO',
    ),
  ];

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
  String? lastOfflineTrackId;

  @override
  Future<Subscription> getMySubscription() async {
    getMySubscriptionCalls++;
    return subscription;
  }

  @override
  Future<List<Plan>> getPlans() async {
    getPlansCalls++;
    return plans;
  }

  @override
  Future<String> createCheckout(String plan) async {
    createCheckoutCalls++;
    lastCheckoutPlan = plan;
    return 'https://checkout.example.com/$plan';
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
      canUpdatePaymentMethod: true,
      canCancel: true,
      canChangePlan: true,
    );
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
  Future<Subscription> cancelPlanChange() async {
    cancelPlanChangeCalls++;

    return subscription.copyWith(clearPendingDowngrade: true);
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