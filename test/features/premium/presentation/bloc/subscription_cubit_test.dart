import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/features/premium/domain/entities/billing_invoice.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_portal_session.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/offline_track_entitlement.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/plan.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_state.dart';

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
    uploadedTracks: 1,
    remainingUploads: 2,
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

  const goPlusSubscription = Subscription(
    userId: 'user-1',
    planCode: 'GO_PLUS',
    subscriptionType: 'GO_PLUS',
    subscriptionStatus: 'ACTIVE',
    planName: 'GO+',
    isPremium: true,
    isUnlimited: true,
    adsEnabled: false,
    canDownload: true,
    uploadLimit: 1000,
    uploadLimitDisplay: '1000',
    uploadedTracks: 10,
    remainingUploads: 990,
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

  const plans = <Plan>[
    freePlan,
    proPlan,
    goPlusPlan,
  ];

  const invoices = <BillingInvoice>[
    BillingInvoice(
      id: 'invoice-1',
      invoiceId: 'in_123',
      amountDueCents: 999,
      amountPaidCents: 999,
      currency: 'USD',
      status: 'PAID',
      planName: 'Pro',
      planTier: 'PRO',
    ),
  ];

  const portalSession = BillingPortalSession(
    url: 'https://billing.example.com/session/test',
    portalUrl: 'https://billing.example.com',
    sessionId: 'bps_123',
    customerId: 'cus_123',
    returnUrl: 'iqa3://billing/return',
    paymentMethodSummary: 'Visa •••• 4242',
    canUpdatePaymentMethod: true,
    canCancel: true,
    canResume: false,
    canChangePlan: true,
  );

  group('SubscriptionCubit', () {
    late _FakeSubscriptionRepository repository;

    setUp(() {
      repository = _FakeSubscriptionRepository(
        subscription: freeSubscription,
        plans: plans,
        invoices: invoices,
        portalSession: portalSession,
      );
    });

    SubscriptionCubit buildCubit() => SubscriptionCubit(repository);

    test('initial state is SubscriptionState.initial()', () async {
      final cubit = buildCubit();

      expect(cubit.state, SubscriptionState.initial());

      await cubit.close();
    });

    blocTest<SubscriptionCubit, SubscriptionState>(
      'loadSubscription emits loading then loaded with subscription and plans',
      build: buildCubit,
      act: (cubit) => cubit.loadSubscription(),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loading,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          subscription: freeSubscription,
          plans: plans,
        ),
      ],
      verify: (_) {
        expect(repository.getMySubscriptionCalls, 1);
        expect(repository.getPlansCalls, 1);
        expect(repository.getInvoicesCalls, 0);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'loadSubscription preserves previous data while loading',
      build: buildCubit,
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: proSubscription,
        plans: plans,
        invoices: invoices,
      ),
      act: (cubit) => cubit.loadSubscription(),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loading,
          subscription: proSubscription,
          plans: plans,
          invoices: invoices,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          subscription: freeSubscription,
          plans: plans,
          invoices: invoices,
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'loadSubscription emits failure with readable message when repository fails',
      build: () {
        repository.getPlansError = Exception('Plans unavailable.');
        return buildCubit();
      },
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: proSubscription,
        plans: <Plan>[proPlan],
        invoices: invoices,
      ),
      act: (cubit) => cubit.loadSubscription(),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loading,
          subscription: proSubscription,
          plans: <Plan>[proPlan],
          invoices: invoices,
        ),
        SubscriptionState(
          status: SubscriptionStatus.failure,
          subscription: proSubscription,
          plans: <Plan>[proPlan],
          invoices: invoices,
          errorMessage: 'Plans unavailable.',
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'loadBilling loads subscription plans and invoices together',
      build: () {
        repository.subscription = proSubscription;
        return buildCubit();
      },
      act: (cubit) => cubit.loadBilling(),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          actionStatus: SubscriptionActionStatus.loading,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.success,
          subscription: proSubscription,
          plans: plans,
          invoices: invoices,
          actionMessage: 'Billing details loaded.',
        ),
      ],
      verify: (_) {
        expect(repository.getMySubscriptionCalls, 1);
        expect(repository.getPlansCalls, 1);
        expect(repository.getInvoicesCalls, 1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'loadBilling emits action failure without clearing existing data',
      build: () {
        repository.getInvoicesError = Exception('Invoices failed.');
        return buildCubit();
      },
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: proSubscription,
        plans: plans,
        invoices: invoices,
      ),
      act: (cubit) => cubit.loadBilling(),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: proSubscription,
          plans: plans,
          invoices: invoices,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.failure,
          subscription: proSubscription,
          plans: plans,
          invoices: invoices,
          actionErrorMessage: 'Invoices failed.',
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'upgrade emits checkout url and success message',
      build: buildCubit,
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: freeSubscription,
        plans: plans,
        invoices: invoices,
        checkoutUrl: 'old-url',
        actionMessage: 'old message',
        actionErrorMessage: 'old error',
      ),
      act: (cubit) async {
        final checkoutUrl = await cubit.upgrade('PRO');
        expect(checkoutUrl, 'https://checkout.example.com/PRO');
      },
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: freeSubscription,
          plans: plans,
          invoices: invoices,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.success,
          subscription: freeSubscription,
          plans: plans,
          invoices: invoices,
          checkoutUrl: 'https://checkout.example.com/PRO',
          actionMessage: 'Checkout session created.',
        ),
      ],
      verify: (_) {
        expect(repository.createCheckoutCalls, 1);
        expect(repository.lastCheckoutPlan, 'PRO');
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'upgrade emits action failure and rethrows when checkout fails',
      build: () {
        repository.createCheckoutError = Exception('Checkout failed.');
        return buildCubit();
      },
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: freeSubscription,
        plans: plans,
        checkoutUrl: 'old-url',
        actionMessage: 'old message',
      ),
      act: (cubit) async {
        try {
          await cubit.upgrade('PRO');
        } catch (_) {}
      },
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: freeSubscription,
          plans: plans,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.failure,
          subscription: freeSubscription,
          plans: plans,
          actionErrorMessage: 'Checkout failed.',
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'subscribe emits redirect url and success message',
      build: buildCubit,
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: freeSubscription,
        plans: plans,
      ),
      act: (cubit) async {
        final redirectUrl = await cubit.subscribe('GO_PLUS');
        expect(redirectUrl, 'https://subscribe.example.com/GO_PLUS');
      },
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: freeSubscription,
          plans: plans,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.success,
          subscription: freeSubscription,
          plans: plans,
          checkoutUrl: 'https://subscribe.example.com/GO_PLUS',
          actionMessage: 'Subscription request created.',
        ),
      ],
      verify: (_) {
        expect(repository.subscribeCalls, 1);
        expect(repository.lastSubscribePlan, 'GO_PLUS');
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'subscribe emits action failure and rethrows when repository fails',
      build: () {
        repository.subscribeError = Exception('Subscribe failed.');
        return buildCubit();
      },
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: freeSubscription,
        plans: plans,
      ),
      act: (cubit) async {
        try {
          await cubit.subscribe('PRO');
        } catch (_) {}
      },
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: freeSubscription,
          plans: plans,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.failure,
          subscription: freeSubscription,
          plans: plans,
          actionErrorMessage: 'Subscribe failed.',
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'refreshAfterPayment reloads subscription and plans',
      build: () {
        repository.subscription = proSubscription;
        return buildCubit();
      },
      act: (cubit) => cubit.refreshAfterPayment(),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loading,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          subscription: proSubscription,
          plans: plans,
        ),
      ],
      verify: (_) {
        expect(repository.getMySubscriptionCalls, 1);
        expect(repository.getPlansCalls, 1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'cancel schedules cancellation and refreshes billing data',
      build: () {
        repository.subscription = proSubscription;
        return buildCubit();
      },
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: proSubscription,
        plans: plans,
        invoices: invoices,
      ),
      act: (cubit) => cubit.cancel(),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: proSubscription,
          plans: plans,
          invoices: invoices,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.success,
          subscription: cancelingSubscription,
          plans: plans,
          invoices: invoices,
          actionMessage: 'Subscription cancellation scheduled.',
        ),
      ],
      verify: (_) {
        expect(repository.cancelSubscriptionCalls, 1);
        expect(repository.getMySubscriptionCalls, 1);
        expect(repository.getPlansCalls, 1);
        expect(repository.getInvoicesCalls, 1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'cancel emits action failure when cancellation fails',
      build: () {
        repository.cancelSubscriptionError = Exception('Cancel failed.');
        repository.subscription = proSubscription;
        return buildCubit();
      },
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: proSubscription,
        plans: plans,
        invoices: invoices,
      ),
      act: (cubit) => cubit.cancel(),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: proSubscription,
          plans: plans,
          invoices: invoices,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.failure,
          subscription: proSubscription,
          plans: plans,
          invoices: invoices,
          actionErrorMessage: 'Cancel failed.',
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'resume restores cancellation and refreshes billing data',
      build: () {
        repository.subscription = cancelingSubscription;
        return buildCubit();
      },
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: cancelingSubscription,
        plans: plans,
        invoices: invoices,
      ),
      act: (cubit) => cubit.resume(),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: cancelingSubscription,
          plans: plans,
          invoices: invoices,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.success,
          subscription: proSubscription,
          plans: plans,
          invoices: invoices,
          actionMessage: 'Subscription resumed.',
        ),
      ],
      verify: (_) {
        expect(repository.resumeSubscriptionCalls, 1);
        expect(repository.getMySubscriptionCalls, 1);
        expect(repository.getPlansCalls, 1);
        expect(repository.getInvoicesCalls, 1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'resume emits action failure when repository fails',
      build: () {
        repository.resumeSubscriptionError = Exception('Resume failed.');
        repository.subscription = cancelingSubscription;
        return buildCubit();
      },
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: cancelingSubscription,
        plans: plans,
        invoices: invoices,
      ),
      act: (cubit) => cubit.resume(),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: cancelingSubscription,
          plans: plans,
          invoices: invoices,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.failure,
          subscription: cancelingSubscription,
          plans: plans,
          invoices: invoices,
          actionErrorMessage: 'Resume failed.',
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'changePlan changes current plan and refreshes billing data',
      build: () {
        repository.subscription = proSubscription;
        return buildCubit();
      },
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: proSubscription,
        plans: plans,
        invoices: invoices,
      ),
      act: (cubit) => cubit.changePlan('GO_PLUS'),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: proSubscription,
          plans: plans,
          invoices: invoices,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.success,
          subscription: goPlusSubscription,
          plans: plans,
          invoices: invoices,
          actionMessage: 'Subscription plan changed.',
        ),
      ],
      verify: (_) {
        expect(repository.changePlanCalls, 1);
        expect(repository.lastChangePlan, 'GO_PLUS');
        expect(repository.getMySubscriptionCalls, 1);
        expect(repository.getPlansCalls, 1);
        expect(repository.getInvoicesCalls, 1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'changePlan emits action failure when repository fails',
      build: () {
        repository.changePlanError = Exception('Change plan failed.');
        repository.subscription = proSubscription;
        return buildCubit();
      },
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: proSubscription,
        plans: plans,
        invoices: invoices,
      ),
      act: (cubit) => cubit.changePlan('GO_PLUS'),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: proSubscription,
          plans: plans,
          invoices: invoices,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.failure,
          subscription: proSubscription,
          plans: plans,
          invoices: invoices,
          actionErrorMessage: 'Change plan failed.',
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'openBillingPortal emits billing portal session and returns launch url',
      build: buildCubit,
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: proSubscription,
        plans: plans,
        billingPortalSession: BillingPortalSession(
          url: 'https://old.example.com',
        ),
        actionMessage: 'old message',
        actionErrorMessage: 'old error',
      ),
      act: (cubit) async {
        final portalUrl = await cubit.openBillingPortal();
        expect(portalUrl, 'https://billing.example.com/session/test');
      },
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: proSubscription,
          plans: plans,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.success,
          subscription: proSubscription,
          plans: plans,
          billingPortalSession: portalSession,
          actionMessage: 'Billing portal opened.',
        ),
      ],
      verify: (_) {
        expect(repository.openBillingPortalSessionCalls, 1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'openBillingPortal emits action failure and rethrows when repository fails',
      build: () {
        repository.openBillingPortalSessionError = Exception('Portal failed.');
        return buildCubit();
      },
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: proSubscription,
        plans: plans,
        billingPortalSession: portalSession,
      ),
      act: (cubit) async {
        try {
          await cubit.openBillingPortal();
        } catch (_) {}
      },
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: proSubscription,
          plans: plans,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.failure,
          subscription: proSubscription,
          plans: plans,
          actionErrorMessage: 'Portal failed.',
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'clearActionStatus clears action messages and returns action status to idle',
      build: buildCubit,
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        actionStatus: SubscriptionActionStatus.failure,
        subscription: proSubscription,
        plans: plans,
        actionMessage: 'old message',
        actionErrorMessage: 'old error',
      ),
      act: (cubit) => cubit.clearActionStatus(),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.idle,
          subscription: proSubscription,
          plans: plans,
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'clearCheckoutUrl removes checkout url only',
      build: buildCubit,
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: proSubscription,
        plans: plans,
        checkoutUrl: 'https://checkout.example.com/PRO',
        actionMessage: 'Checkout session created.',
      ),
      act: (cubit) => cubit.clearCheckoutUrl(),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          subscription: proSubscription,
          plans: plans,
          actionMessage: 'Checkout session created.',
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'successful cancel keeps action success even if follow-up refresh fails',
      build: () {
        repository.subscription = proSubscription;
        repository.refreshAfterActionError = Exception('Refresh failed.');
        return buildCubit();
      },
      seed: () => const SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: proSubscription,
        plans: plans,
        invoices: invoices,
      ),
      act: (cubit) => cubit.cancel(),
      expect: () => const <SubscriptionState>[
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.loading,
          subscription: proSubscription,
          plans: plans,
          invoices: invoices,
        ),
        SubscriptionState(
          status: SubscriptionStatus.loaded,
          actionStatus: SubscriptionActionStatus.success,
          subscription: cancelingSubscription,
          plans: plans,
          invoices: invoices,
          actionMessage: 'Subscription cancellation scheduled.',
        ),
      ],
      verify: (_) {
        expect(repository.cancelSubscriptionCalls, 1);
        expect(repository.getMySubscriptionCalls, 1);
      },
    );
  });
}

class _FakeSubscriptionRepository extends SubscriptionRepository {
  _FakeSubscriptionRepository({
    required this.subscription,
    required this.plans,
    required this.invoices,
    required this.portalSession,
  });

  Subscription subscription;
  List<Plan> plans;
  List<BillingInvoice> invoices;
  BillingPortalSession portalSession;

  Object? getMySubscriptionError;
  Object? getPlansError;
  Object? getInvoicesError;
  Object? createCheckoutError;
  Object? subscribeError;
  Object? cancelSubscriptionError;
  Object? resumeSubscriptionError;
  Object? changePlanError;
  Object? openBillingPortalSessionError;
  Object? refreshAfterActionError;

  int getMySubscriptionCalls = 0;
  int getPlansCalls = 0;
  int getInvoicesCalls = 0;
  int createCheckoutCalls = 0;
  int subscribeCalls = 0;
  int cancelSubscriptionCalls = 0;
  int resumeSubscriptionCalls = 0;
  int changePlanCalls = 0;
  int openBillingPortalSessionCalls = 0;
  int getOfflineTrackEntitlementCalls = 0;

  String? lastCheckoutPlan;
  String? lastSubscribePlan;
  String? lastChangePlan;

  @override
  Future<Subscription> getMySubscription() async {
    getMySubscriptionCalls++;

    final refreshError = refreshAfterActionError;
    if (refreshError != null && getMySubscriptionCalls > 0) {
      refreshAfterActionError = null;
      throw refreshError;
    }

    final error = getMySubscriptionError;
    if (error != null) {
      throw error;
    }

    return subscription;
  }

  @override
  Future<List<Plan>> getPlans() async {
    getPlansCalls++;

    final error = getPlansError;
    if (error != null) {
      throw error;
    }

    return plans;
  }

  @override
  Future<String> createCheckout(String plan) async {
    createCheckoutCalls++;
    lastCheckoutPlan = plan;

    final error = createCheckoutError;
    if (error != null) {
      throw error;
    }

    return 'https://checkout.example.com/$plan';
  }

  @override
  Future<String> subscribe(String plan) async {
    subscribeCalls++;
    lastSubscribePlan = plan;

    final error = subscribeError;
    if (error != null) {
      throw error;
    }

    return 'https://subscribe.example.com/$plan';
  }

  @override
  Future<BillingPortalSession> openBillingPortalSession() async {
    openBillingPortalSessionCalls++;

    final error = openBillingPortalSessionError;
    if (error != null) {
      throw error;
    }

    return portalSession;
  }

  @override
  Future<List<BillingInvoice>> getInvoices() async {
    getInvoicesCalls++;

    final error = getInvoicesError;
    if (error != null) {
      throw error;
    }

    return invoices;
  }

  @override
  Future<Subscription> cancelSubscription() async {
    cancelSubscriptionCalls++;

    final error = cancelSubscriptionError;
    if (error != null) {
      throw error;
    }

    subscription = subscription.copyWith(
      cancelAtPeriodEnd: true,
      canResume: true,
    );

    return subscription;
  }

  @override
  Future<Subscription> resumeSubscription() async {
    resumeSubscriptionCalls++;

    final error = resumeSubscriptionError;
    if (error != null) {
      throw error;
    }

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
        uploadedTracks: 10,
        remainingUploads: 990,
        cancelAtPeriodEnd: false,
        canResume: false,
      );
    } else if (normalizedPlan == 'PRO') {
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
        uploadedTracks: 10,
        remainingUploads: 90,
        cancelAtPeriodEnd: false,
        canResume: false,
      );
    } else {
      subscription = subscription.copyWith(
        planCode: 'FREE',
        subscriptionType: 'FREE',
        planName: 'Free',
        isPremium: false,
        isUnlimited: false,
        adsEnabled: true,
        canDownload: false,
        uploadLimit: 3,
        uploadLimitDisplay: '3',
        uploadedTracks: 1,
        remainingUploads: 2,
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