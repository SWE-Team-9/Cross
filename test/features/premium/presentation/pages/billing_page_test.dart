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

  const cancelingSubscription = Subscription(
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
    cancelAtPeriodEnd: true,
    canResume: true,
    paymentMethodSummary: 'Visa •••• 4242',
  );

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
    uploadedTracks: 1,
    remainingUploads: 2,
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

  const goPlusPlan = Plan(
    code: 'GO_PLUS',
    name: 'GO+',
    tier: 'GO_PLUS',
    priceCents: 1999,
    priceDisplay: r'$19.99/mo',
    billingInterval: 'MONTHLY',
    uploadLimit: 1000,
    uploadLimitDisplay: '1000',
    adsEnabled: false,
    canDownload: true,
    supportLevel: 'priority',
  );

  const plans = <Plan>[proPlan, goPlusPlan];

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

  group('BillingPage', () {
    testWidgets('loads billing details and renders premium subscription summary',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: plans,
        invoices: const <BillingInvoice>[invoice],
      );

      await _pumpBillingPage(tester, repository);

      expect(find.text('Billing'), findsOneWidget);
      expect(find.text('Subscription'), findsOneWidget);
      expect(find.text('Pro'), findsWidgets);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('90 remaining / 100'), findsOneWidget);
      expect(find.text('Unlocked'), findsOneWidget);
      expect(find.text('Ad-free'), findsOneWidget);
      expect(find.text('Visa •••• 4242'), findsOneWidget);
      expect(find.text('Open portal'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text(r'$9.99'), findsOneWidget);
      expect(find.textContaining('Paid'), findsOneWidget);

      expect(repository.getMySubscriptionCalls, 1);
      expect(repository.getPlansCalls, 1);
      expect(repository.getInvoicesCalls, 1);
    });

    testWidgets('renders free subscription with locked premium actions',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: plans,
      );

      await _pumpBillingPage(tester, repository);

      expect(find.text('Free'), findsWidgets);
      expect(find.text('2 remaining / 3'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
      expect(find.text('Premium'), findsNothing);
      expect(find.text('Cancel'), findsNothing);

      final openPortalButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Open portal'),
      );
      expect(openPortalButton.onPressed, isNull);
    });

    testWidgets('shows empty invoice message when there are no invoices',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: plans,
      );

      await _pumpBillingPage(tester, repository);

      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('No invoices yet.'), findsOneWidget);
    });

    testWidgets('app bar refresh reloads billing details', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: plans,
        invoices: const <BillingInvoice>[invoice],
      );

      await _pumpBillingPage(tester, repository);

      expect(repository.getMySubscriptionCalls, 1);
      expect(repository.getPlansCalls, 1);
      expect(repository.getInvoicesCalls, 1);

      await tester.tap(find.byTooltip('Refresh billing'));
      await tester.pumpAndSettle();

      expect(repository.getMySubscriptionCalls, 2);
      expect(repository.getPlansCalls, 2);
      expect(repository.getInvoicesCalls, 2);
    });

    testWidgets('invoice section refresh reloads billing details',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: plans,
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.widgetWithText(TextButton, 'Refresh'));
      await tester.pumpAndSettle();

      expect(repository.getMySubscriptionCalls, 2);
      expect(repository.getPlansCalls, 2);
      expect(repository.getInvoicesCalls, 2);
    });

    testWidgets('open portal validates invalid portal link', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: plans,
        portalSession: const BillingPortalSession(
          url: 'not-a-valid-url',
          sessionId: 'bps_invalid',
        ),
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.text('Open portal'));
      await tester.pumpAndSettle();

      expect(repository.openBillingPortalSessionCalls, 1);
      expect(find.text('Invalid link returned from the server.'), findsOneWidget);
    });

    testWidgets('open portal shows unavailable message when portal link is empty',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: plans,
        portalSession: const BillingPortalSession(),
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.text('Open portal'));
      await tester.pumpAndSettle();

      expect(repository.openBillingPortalSessionCalls, 1);
      expect(find.text('Billing portal is not available right now.'), findsOneWidget);
    });

    testWidgets('open portal error shows snackbar', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: plans,
        openPortalError: Exception('Portal failed.'),
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.text('Open portal'));
      await tester.pumpAndSettle();

      expect(repository.openBillingPortalSessionCalls, 1);
      expect(find.text('Portal failed.'), findsOneWidget);
    });

    testWidgets('cancel flow schedules cancellation and shows resume action',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: plans,
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel subscription?'), findsOneWidget);
      expect(find.text('Keep plan'), findsOneWidget);
      expect(find.text('Cancel plan'), findsOneWidget);

      await tester.tap(find.text('Cancel plan'));
      await tester.pumpAndSettle();

      expect(repository.cancelSubscriptionCalls, 1);
      expect(find.text('Subscription cancellation scheduled.'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(
        find.text(
          'Cancellation is scheduled. You can resume before the billing period ends.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('cancel dialog keep plan does not cancel subscription',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: plans,
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Keep plan'));
      await tester.pumpAndSettle();

      expect(repository.cancelSubscriptionCalls, 0);
      expect(find.text('Cancel subscription?'), findsNothing);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('resume flow restores active subscription', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: cancelingSubscription,
        plans: plans,
      );

      await _pumpBillingPage(tester, repository);

      expect(find.text('Resume'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Resume'));
      await tester.pumpAndSettle();

      expect(find.text('Resume subscription?'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);

      await tester.tap(find.text('Resume').last);
      await tester.pumpAndSettle();

      expect(repository.resumeSubscriptionCalls, 1);
      expect(find.text('Subscription resumed.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Resume'), findsNothing);
    });

    testWidgets('resume dialog not now does not resume subscription',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: cancelingSubscription,
        plans: plans,
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.widgetWithText(FilledButton, 'Resume'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(repository.resumeSubscriptionCalls, 0);
      expect(find.text('Resume subscription?'), findsNothing);
      expect(find.text('Resume'), findsOneWidget);
    });

    testWidgets('switch plan changes subscription plan', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: plans,
      );

      await _pumpBillingPage(tester, repository);

      expect(find.text('Change plan'), findsOneWidget);
      expect(find.text('GO+'), findsOneWidget);
      expect(find.text('Switch'), findsOneWidget);

      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();

      expect(repository.changePlanCalls, 1);
      expect(repository.lastChangePlan, 'GO_PLUS');
      expect(find.text('Subscription plan changed.'), findsOneWidget);
      expect(find.text('GO+'), findsWidgets);
    });

    testWidgets('switch plan error shows snackbar', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: plans,
        changePlanError: Exception('Plan change failed.'),
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();

      expect(repository.changePlanCalls, 1);
      expect(find.text('Plan change failed.'), findsOneWidget);
    });

    testWidgets('load billing error shows snackbar and keeps base page',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: plans,
        loadBillingError: Exception('Billing load failed.'),
      );

      await _pumpBillingPage(tester, repository);

      expect(find.text('Billing'), findsOneWidget);
      expect(find.text('Billing load failed.'), findsOneWidget);
    });
  });
}

Future<void> _pumpBillingPage(
  WidgetTester tester,
  _FakeSubscriptionRepository repository,
) async {
  tester.view.physicalSize = const Size(1200, 2200);
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<SubscriptionCubit>(
        create: (_) => SubscriptionCubit(repository),
        child: const BillingPage(),
      ),
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
    required this.subscription,
    this.plans = const <Plan>[],
    this.invoices = const <BillingInvoice>[],
    this.portalSession = const BillingPortalSession(
      url: 'not-a-valid-url',
      sessionId: 'bps_test',
    ),
    this.loadBillingError,
    this.openPortalError,
    this.changePlanError,
  });

  Subscription subscription;
  List<Plan> plans;
  List<BillingInvoice> invoices;
  BillingPortalSession portalSession;

  Object? loadBillingError;
  Object? openPortalError;
  Object? changePlanError;

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

    final error = openPortalError;
    if (error != null) {
      throw error;
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

    final error = changePlanError;
    if (error != null) {
      throw error;
    }

    final normalizedPlan = plan.trim().toUpperCase();

    if (normalizedPlan == 'GO_PLUS') {
      subscription = subscription.copyWith(
        planCode: 'GO_PLUS',
        subscriptionType: 'GO_PLUS',
        planName: 'GO+',
        isPremium: true,
        isUnlimited: true,
        adsEnabled: false,
        canDownload: true,
        uploadLimit: 1000,
        uploadLimitDisplay: '1000',
        remainingUploads: 990,
        cancelAtPeriodEnd: false,
        canResume: false,
      );
    } else {
      subscription = subscription.copyWith(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        planName: 'Pro',
        isPremium: true,
        isUnlimited: false,
        adsEnabled: false,
        canDownload: true,
        uploadLimit: 100,
        uploadLimitDisplay: '100',
        remainingUploads: 90,
        cancelAtPeriodEnd: false,
        canResume: false,
      );
    }

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