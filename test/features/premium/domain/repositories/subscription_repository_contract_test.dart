import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_invoice.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_portal_session.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/offline_track_entitlement.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/plan.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';

void main() {
  group('SubscriptionRepository contract', () {
    test('openPortal returns launchUrl from openBillingPortalSession', () async {
      final repository = _FakeSubscriptionRepository(
        portalSession: const BillingPortalSession(
          url: 'https://billing.stripe.com/session/test',
          portalUrl: 'https://fallback.example.com/session/test',
        ),
      );

      final portalUrl = await repository.openPortal();

      expect(portalUrl, 'https://billing.stripe.com/session/test');
      expect(repository.openBillingPortalSessionCalls, 1);
    });

    test('openPortal falls back to portalUrl when url is empty', () async {
      final repository = _FakeSubscriptionRepository(
        portalSession: const BillingPortalSession(
          portalUrl: 'https://billing.example.com/session/test',
        ),
      );

      final portalUrl = await repository.openPortal();

      expect(portalUrl, 'https://billing.example.com/session/test');
      expect(repository.openBillingPortalSessionCalls, 1);
    });

    test('contract exposes subscription status', () async {
      final repository = _FakeSubscriptionRepository(
        subscription: const Subscription(
          planCode: 'PRO',
          subscriptionType: 'PRO',
          subscriptionStatus: 'ACTIVE',
          isPremium: true,
        ),
      );

      final subscription = await repository.getMySubscription();

      expect(subscription.planCode, 'PRO');
      expect(subscription.isPremium, isTrue);
      expect(repository.getMySubscriptionCalls, 1);
    });

    test('contract exposes plans', () async {
      final repository = _FakeSubscriptionRepository(
        plans: const <Plan>[
          Plan(code: 'FREE', name: 'Free'),
          Plan(code: 'PRO', name: 'Pro'),
        ],
      );

      final plans = await repository.getPlans();

      expect(plans.map((plan) => plan.code), <String>['FREE', 'PRO']);
      expect(repository.getPlansCalls, 1);
    });

    test('contract exposes checkout creation', () async {
      final repository = _FakeSubscriptionRepository(
        checkoutUrl: 'https://checkout.example.com/pro',
      );

      final checkoutUrl = await repository.createCheckout('PRO');

      expect(checkoutUrl, 'https://checkout.example.com/pro');
      expect(repository.lastCheckoutPlan, 'PRO');
      expect(repository.createCheckoutCalls, 1);
    });

    test('contract exposes legacy subscribe flow', () async {
      final repository = _FakeSubscriptionRepository(
        subscribeUrl: 'https://subscribe.example.com/pro',
      );

      final subscribeUrl = await repository.subscribe('PRO');

      expect(subscribeUrl, 'https://subscribe.example.com/pro');
      expect(repository.lastSubscribePlan, 'PRO');
      expect(repository.subscribeCalls, 1);
    });

    test('contract exposes invoices', () async {
      final repository = _FakeSubscriptionRepository(
        invoices: const <BillingInvoice>[
          BillingInvoice(
            invoiceId: 'in_1',
            amountPaidCents: 999,
            status: 'PAID',
          ),
          BillingInvoice(
            invoiceId: 'in_2',
            amountPaidCents: 1999,
            status: 'PAID',
          ),
        ],
      );

      final invoices = await repository.getInvoices();

      expect(invoices.map((invoice) => invoice.invoiceId), <String>[
        'in_1',
        'in_2',
      ]);
      expect(repository.getInvoicesCalls, 1);
    });

    test('contract exposes cancel subscription', () async {
      final repository = _FakeSubscriptionRepository(
        canceledSubscription: const Subscription(
          planCode: 'PRO',
          subscriptionType: 'PRO',
          subscriptionStatus: 'ACTIVE',
          isPremium: true,
          cancelAtPeriodEnd: true,
          canResume: true,
        ),
      );

      final subscription = await repository.cancelSubscription();

      expect(subscription.cancelAtPeriodEnd, isTrue);
      expect(subscription.canResume, isTrue);
      expect(repository.cancelSubscriptionCalls, 1);
    });

    test('contract exposes resume subscription', () async {
      final repository = _FakeSubscriptionRepository(
        resumedSubscription: const Subscription(
          planCode: 'PRO',
          subscriptionType: 'PRO',
          subscriptionStatus: 'ACTIVE',
          isPremium: true,
          cancelAtPeriodEnd: false,
          canResume: false,
        ),
      );

      final subscription = await repository.resumeSubscription();

      expect(subscription.cancelAtPeriodEnd, isFalse);
      expect(subscription.canResume, isFalse);
      expect(repository.resumeSubscriptionCalls, 1);
    });

    test('contract exposes change plan', () async {
      final repository = _FakeSubscriptionRepository(
        changedPlanSubscription: const Subscription(
          planCode: 'GO_PLUS',
          subscriptionType: 'GO_PLUS',
          subscriptionStatus: 'ACTIVE',
          isPremium: true,
        ),
      );

      final subscription = await repository.changePlan('GO_PLUS');

      expect(subscription.planCode, 'GO_PLUS');
      expect(repository.lastChangePlan, 'GO_PLUS');
      expect(repository.changePlanCalls, 1);
    });

    test('contract exposes cancel plan change', () async {
      final repository = _FakeSubscriptionRepository(
        canceledPlanChangeSubscription: const Subscription(
          planCode: 'PRO',
          subscriptionType: 'PRO',
          subscriptionStatus: 'ACTIVE',
          isPremium: true,
        ),
      );

      final subscription = await repository.cancelPlanChange();

      expect(subscription.hasPendingDowngrade, isFalse);
      expect(repository.cancelPlanChangeCalls, 1);
    });

    test('contract exposes offline track entitlement', () async {
      final repository = _FakeSubscriptionRepository(
        entitlement: const OfflineTrackEntitlement(
          trackId: 'track-1',
          title: 'Midnight Drive',
          planCode: 'PRO',
        ),
      );

      final entitlement =
          await repository.getOfflineTrackEntitlement('track-1');

      expect(entitlement.trackId, 'track-1');
      expect(entitlement.title, 'Midnight Drive');
      expect(entitlement.isAllowed, isTrue);
      expect(repository.lastOfflineTrackId, 'track-1');
      expect(repository.getOfflineTrackEntitlementCalls, 1);
    });
  });
}

class _FakeSubscriptionRepository extends SubscriptionRepository {
  _FakeSubscriptionRepository({
    this.subscription = const Subscription(),
    this.plans = const <Plan>[],
    this.checkoutUrl = 'https://checkout.example.com/default',
    this.subscribeUrl = 'https://subscribe.example.com/default',
    this.portalSession = const BillingPortalSession(
      url: 'https://billing.example.com/default',
    ),
    this.invoices = const <BillingInvoice>[],
    this.canceledSubscription = const Subscription(
      cancelAtPeriodEnd: true,
      canResume: true,
    ),
    this.resumedSubscription = const Subscription(
      cancelAtPeriodEnd: false,
      canResume: false,
    ),
    this.changedPlanSubscription = const Subscription(
      planCode: 'PRO',
      subscriptionType: 'PRO',
      subscriptionStatus: 'ACTIVE',
      isPremium: true,
    ),
    this.canceledPlanChangeSubscription = const Subscription(
      planCode: 'PRO',
      subscriptionType: 'PRO',
      subscriptionStatus: 'ACTIVE',
      isPremium: true,
    ),
    this.entitlement = const OfflineTrackEntitlement(
      trackId: 'track-1',
      planCode: 'PRO',
    ),
  });

  final Subscription subscription;
  final List<Plan> plans;
  final String checkoutUrl;
  final String subscribeUrl;
  final BillingPortalSession portalSession;
  final List<BillingInvoice> invoices;
  final Subscription canceledSubscription;
  final Subscription resumedSubscription;
  final Subscription changedPlanSubscription;
  final Subscription canceledPlanChangeSubscription;
  final OfflineTrackEntitlement entitlement;

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
    return checkoutUrl;
  }

  @override
  Future<String> subscribe(String plan) async {
    subscribeCalls++;
    lastSubscribePlan = plan;
    return subscribeUrl;
  }

  @override
  Future<BillingPortalSession> openBillingPortalSession() async {
    openBillingPortalSessionCalls++;
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
    return canceledSubscription;
  }

  @override
  Future<Subscription> resumeSubscription() async {
    resumeSubscriptionCalls++;
    return resumedSubscription;
  }

  @override
  Future<Subscription> changePlan(String plan) async {
    changePlanCalls++;
    lastChangePlan = plan;
    return changedPlanSubscription;
  }

  @override
  Future<Subscription> cancelPlanChange() async {
    cancelPlanChangeCalls++;
    return canceledPlanChangeSubscription;
  }

  @override
  Future<OfflineTrackEntitlement> getOfflineTrackEntitlement(
    String trackId,
  ) async {
    getOfflineTrackEntitlementCalls++;
    lastOfflineTrackId = trackId;
    return entitlement;
  }
}