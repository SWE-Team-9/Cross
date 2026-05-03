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
  const proPlan = Plan(
    code: 'PRO',
    name: 'Pro',
    priceDisplay: r'$9.99/mo',
    billingInterval: 'MONTHLY',
    uploadLimit: 100,
    uploadLimitDisplay: '100',
    adsEnabled: false,
    canDownload: true,
  );

  const goPlusPlan = Plan(
    code: 'GO_PLUS',
    name: 'GO+',
    priceDisplay: r'$19.99/mo',
    billingInterval: 'MONTHLY',
    uploadLimit: 1000,
    uploadLimitDisplay: '1000',
    adsEnabled: false,
    canDownload: true,
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
    uploadedTracks: 5,
    remainingUploads: 95,
    cancelAtPeriodEnd: true,
    canResume: true,
  );

  const invoice = BillingInvoice(
    invoiceId: 'in_mock_abc123',
    amountPaidCents: 999,
    currency: 'USD',
    status: 'PAID',
    planName: 'Pro',
    planTier: 'PRO',
  );

  tearDown(_resetTestView);

  group('BillingPage', () {
    testWidgets('loads billing and renders subscription summary', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan, goPlusPlan],
        invoices: const <BillingInvoice>[invoice],
      );

      await _pumpBillingPage(tester, repository);

      expect(find.text('Billing'), findsOneWidget);
      expect(find.text('Subscription'), findsOneWidget);
      expect(find.text('Pro'), findsWidgets);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('95 remaining / 100'), findsOneWidget);
      expect(find.text('Unlocked'), findsOneWidget);
      expect(find.text('Ad-free'), findsOneWidget);
      expect(find.text('Visa •••• 4242'), findsOneWidget);
      expect(find.text('Open portal'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Change plan'), findsOneWidget);
      expect(find.text('GO+'), findsOneWidget);
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text(r'$9.99'), findsOneWidget);

      expect(repository.getMySubscriptionCalls, 1);
      expect(repository.getInvoicesCalls, 1);
    });

    testWidgets('renders no invoices state', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
      );

      await _pumpBillingPage(tester, repository);

      expect(find.text('No invoices yet.'), findsOneWidget);
    });

    testWidgets('shows loading indicator while billing loads', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
        responseDelay: const Duration(milliseconds: 300),
      );

      await _pumpBillingPage(tester, repository, settle: false);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      await tester.pumpAndSettle();
    });

    testWidgets('refresh billing action reloads billing data', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
      );

      await _pumpBillingPage(tester, repository);

      expect(repository.getMySubscriptionCalls, 1);

      await tester.tap(find.byTooltip('Refresh billing'));
      await tester.pumpAndSettle();

      expect(repository.getMySubscriptionCalls, 2);
      expect(repository.getInvoicesCalls, 2);
    });

    testWidgets('invoice refresh button reloads billing data', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
        invoices: const <BillingInvoice>[invoice],
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.widgetWithText(TextButton, 'Refresh'));
      await tester.pumpAndSettle();

      expect(repository.getMySubscriptionCalls, 2);
      expect(repository.getInvoicesCalls, 2);
    });

    testWidgets('cancel dialog can be dismissed with Keep plan', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel subscription?'), findsOneWidget);

      await tester.tap(find.text('Keep plan'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel subscription?'), findsNothing);
      expect(repository.cancelSubscriptionCalls, 0);
    });

    testWidgets('confirming cancel calls repository and shows success snackbar',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel plan'));
      await tester.pumpAndSettle();

      expect(repository.cancelSubscriptionCalls, 1);
      expect(
        find.text('Subscription cancellation scheduled.'),
        findsOneWidget,
      );
    });

    testWidgets('resume button calls repository and shows success snackbar',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: cancelingSubscription,
        plans: const <Plan>[proPlan],
      );

      await _pumpBillingPage(tester, repository);

      expect(find.text('Resume'), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();

      expect(find.text('Resume subscription?'), findsOneWidget);

      await tester.tap(find.text('Resume').last);
      await tester.pumpAndSettle();

      expect(repository.resumeSubscriptionCalls, 1);
      expect(find.text('Subscription resumed.'), findsOneWidget);
    });

    testWidgets('switch plan calls changePlan and shows success snackbar',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan, goPlusPlan],
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();

      expect(repository.changePlanCalls, 1);
      expect(repository.lastChangePlan, 'GO_PLUS');
      expect(find.text('Subscription plan changed.'), findsOneWidget);
    });

    testWidgets('open portal creates session and validates returned url',
        (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
        portalSession: const BillingPortalSession(
          url: 'not-a-valid-url',
          sessionId: 'bps_123',
        ),
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.text('Open portal'));
      await tester.pumpAndSettle();

      expect(repository.openBillingPortalSessionCalls, 1);
      expect(find.text('Billing portal opened.'), findsOneWidget);
      expect(
        find.text('Invalid link returned from the server.'),
        findsOneWidget,
      );
    });

    testWidgets('billing load error shows snackbar', (tester) async {
      final repository = _FakeSubscriptionRepository(
        loadBillingError: Exception('Billing failed.'),
      );

      await _pumpBillingPage(tester, repository);

      expect(find.text('Billing failed.'), findsOneWidget);
    });

    testWidgets('cancel error shows snackbar', (tester) async {
      final repository = _FakeSubscriptionRepository(
        subscription: proSubscription,
        plans: const <Plan>[proPlan],
        cancelError: Exception('Cancel failed.'),
      );

      await _pumpBillingPage(tester, repository);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel plan'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel failed.'), findsOneWidget);
    });
  });
}

Future<void> _pumpBillingPage(
  WidgetTester tester,
  _FakeSubscriptionRepository repository, {
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<SubscriptionCubit>(
        create: (_) => SubscriptionCubit(repository)..loadSubscription(),
        child: const BillingPage(),
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
    this.portalSession = const BillingPortalSession(
      url: 'https://billing.example.com/session/test',
      sessionId: 'bps_123',
    ),
    this.loadBillingError,
    this.cancelError,
    this.responseDelay = Duration.zero,
  });

  final Subscription subscription;
  final List<Plan> plans;
  final List<BillingInvoice> invoices;
  final BillingPortalSession portalSession;
  final Exception? loadBillingError;
  final Exception? cancelError;
  final Duration responseDelay;

  int getMySubscriptionCalls = 0;
  int getPlansCalls = 0;
  int getInvoicesCalls = 0;
  int openBillingPortalSessionCalls = 0;
  int cancelSubscriptionCalls = 0;
  int resumeSubscriptionCalls = 0;
  int changePlanCalls = 0;
  int cancelPlanChangeCalls = 0;
  String? lastChangePlan;

  Future<void> _delayIfNeeded() async {
    if (responseDelay == Duration.zero) return;
    await Future<void>.delayed(responseDelay);
  }

  @override
  Future<Subscription> getMySubscription() async {
    getMySubscriptionCalls++;
    await _delayIfNeeded();

    if (loadBillingError != null) {
      throw loadBillingError!;
    }

    return subscription;
  }

  @override
  Future<List<Plan>> getPlans() async {
    getPlansCalls++;
    await _delayIfNeeded();
    return plans;
  }

  @override
  Future<List<BillingInvoice>> getInvoices() async {
    getInvoicesCalls++;
    await _delayIfNeeded();

    if (loadBillingError != null) {
      throw loadBillingError!;
    }

    return invoices;
  }

  @override
  Future<String> createCheckout(String plan) async {
    return 'https://checkout.example.com/$plan';
  }

  @override
  Future<String> subscribe(String plan) async {
    return 'https://subscribe.example.com/$plan';
  }

  @override
  Future<BillingPortalSession> openBillingPortalSession() async {
    openBillingPortalSessionCalls++;
    return portalSession;
  }

  @override
  Future<Subscription> cancelSubscription() async {
    cancelSubscriptionCalls++;

    if (cancelError != null) {
      throw cancelError!;
    }

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
      planName: plan == 'GO_PLUS' ? 'GO+' : plan,
      isPremium: plan != 'FREE',
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
    return OfflineTrackEntitlement(
      trackId: trackId,
      planCode: subscription.planCode,
    );
  }
}