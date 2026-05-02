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
import 'package:soundcloud_clone/features/premium/presentation/pages/billing_page.dart';

void main() {
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
    uploadedTracks: 10,
    remainingUploads: 90,
    paymentMethodSummary: 'Visa •••• 4242',
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
    adsEnabled: false,
    canDownload: true,
    supportLevel: 'priority',
  );

  const invoice = BillingInvoice(
    id: 'invoice-1',
    invoiceId: 'in_123',
    amountDueCents: 999,
    amountPaidCents: 999,
    currency: 'USD',
    status: 'PAID',
    planName: 'Pro',
    planTier: 'PRO',
  );

  tearDown(_resetTestView);

  group('BillingPage billing return query handling', () {
    testWidgets('shows success message and refreshes billing details',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
        invoices: const <BillingInvoice>[invoice],
      );

      await _pumpBillingReturnPage(
        tester,
        repository,
        initialLocation:
            '/billing?status=success&plan=pro&checkout_session_id=cs_123',
      );

      expect(
        find.text('Payment confirmed for PRO. Refreshing billing details.'),
        findsOneWidget,
      );
      expect(find.text('Billing'), findsOneWidget);
      expect(find.text('Subscription'), findsOneWidget);
      expect(repository.getMySubscriptionCalls, 1);
      expect(repository.getPlansCalls, 1);
      expect(repository.getInvoicesCalls, 1);
    });

    testWidgets('shows completed status as success message', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
      );

      await _pumpBillingReturnPage(
        tester,
        repository,
        initialLocation: '/billing?paymentStatus=completed&planCode=GO_PLUS',
      );

      expect(
        find.text('Payment confirmed for GO_PLUS. Refreshing billing details.'),
        findsOneWidget,
      );
      expect(repository.getMySubscriptionCalls, 1);
      expect(repository.getPlansCalls, 1);
      expect(repository.getInvoicesCalls, 1);
    });

    testWidgets('shows canceled checkout message', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
      );

      await _pumpBillingReturnPage(
        tester,
        repository,
        initialLocation: '/billing?status=cancelled&session_id=bps_123',
      );

      expect(
        find.text('Checkout was canceled. No billing changes were made.'),
        findsOneWidget,
      );
      expect(repository.getMySubscriptionCalls, 1);
      expect(repository.getPlansCalls, 1);
      expect(repository.getInvoicesCalls, 1);
    });

    testWidgets('shows generic returned status message', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
      );

      await _pumpBillingReturnPage(
        tester,
        repository,
        initialLocation: '/billing?billing_status=pending&subscription_id=sub_123',
      );

      expect(
        find.text('Billing returned with status: pending. Refreshing details.'),
        findsOneWidget,
      );
      expect(repository.getMySubscriptionCalls, 1);
      expect(repository.getPlansCalls, 1);
      expect(repository.getInvoicesCalls, 1);
    });

    testWidgets('shows returned from billing message when only session exists',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
      );

      await _pumpBillingReturnPage(
        tester,
        repository,
        initialLocation: '/billing?checkoutSessionId=cs_123',
      );

      expect(
        find.text('Returned from billing. Refreshing billing details.'),
        findsOneWidget,
      );
      expect(repository.getMySubscriptionCalls, 1);
      expect(repository.getPlansCalls, 1);
      expect(repository.getInvoicesCalls, 1);
    });

    testWidgets('normal billing route loads without return snackbar',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
      );

      await _pumpBillingReturnPage(
        tester,
        repository,
        initialLocation: '/billing',
      );

      expect(
        find.text('Returned from billing. Refreshing billing details.'),
        findsNothing,
      );
      expect(
        find.text('Payment confirmed for PRO. Refreshing billing details.'),
        findsNothing,
      );
      expect(repository.getMySubscriptionCalls, 1);
      expect(repository.getPlansCalls, 1);
      expect(repository.getInvoicesCalls, 1);
    });

    testWidgets('load error after return shows return message then error message',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
        loadBillingError: Exception('Billing refresh failed.'),
      );

      await _pumpBillingReturnPage(
        tester,
        repository,
        initialLocation: '/billing?status=success&plan=PRO',
      );

      expect(find.text('Billing'), findsOneWidget);
      expect(find.text('Billing refresh failed.'), findsOneWidget);
      expect(repository.getMySubscriptionCalls, 1);
      expect(repository.getPlansCalls, 0);
      expect(repository.getInvoicesCalls, 0);
    });
  });
}

Future<void> _pumpBillingReturnPage(
  WidgetTester tester,
  _FakeSubscriptionRepository repository, {
  required String initialLocation,
}) async {
  tester.view.physicalSize = const Size(1200, 2200);
  tester.view.devicePixelRatio = 1.0;

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/billing',
        builder: (context, state) {
          return BlocProvider<SubscriptionCubit>(
            create: (_) => SubscriptionCubit(repository),
            child: const BillingPage(),
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

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void _resetTestView() {
  final binding = TestWidgetsFlutterBinding.instance;
  binding.platformDispatcher.views.first.resetPhysicalSize();
  binding.platformDispatcher.views.first.resetDevicePixelRatio();
}

class _FakeSubscriptionRepository extends SubscriptionRepository {
  _FakeSubscriptionRepository({
    required this.subscription,
    this.plans = const <Plan>[],
    this.invoices = const <BillingInvoice>[],
    this.loadBillingError,
  });

  Subscription subscription;
  List<Plan> plans;
  List<BillingInvoice> invoices;
  Object? loadBillingError;

  int getMySubscriptionCalls = 0;
  int getPlansCalls = 0;
  int getInvoicesCalls = 0;
  int createCheckoutCalls = 0;
  int subscribeCalls = 0;
  int openBillingPortalSessionCalls = 0;
  int cancelSubscriptionCalls = 0;
  int resumeSubscriptionCalls = 0;
  int changePlanCalls = 0;
  int getOfflineTrackEntitlementCalls = 0;

  String? lastCheckoutPlan;
  String? lastSubscribePlan;
  String? lastChangePlan;

  @override
  Future<Subscription> getMySubscription() async {
    getMySubscriptionCalls++;

    final error = loadBillingError;
    if (error != null) {
      loadBillingError = null;
      throw error;
    }

    return subscription;
  }

  @override
  Future<List<Plan>> getPlans() async {
    getPlansCalls++;
    return plans;
  }

  @override
  Future<List<BillingInvoice>> getInvoices() async {
    getInvoicesCalls++;
    return invoices;
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
    );
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