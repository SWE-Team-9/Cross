import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_invoice.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_portal_session.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/plan.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_state.dart';

void main() {
  group('SubscriptionState', () {
    test('initial factory returns default initial state', () {
      final state = SubscriptionState.initial();

      expect(state.status, SubscriptionStatus.initial);
      expect(state.actionStatus, SubscriptionActionStatus.idle);
      expect(state.subscription, const Subscription());
      expect(state.plans, isEmpty);
      expect(state.invoices, isEmpty);
      expect(state.billingPortalSession, isNull);
      expect(state.checkoutUrl, isNull);
      expect(state.actionMessage, isNull);
      expect(state.errorMessage, isNull);
      expect(state.actionErrorMessage, isNull);

      expect(state.isInitial, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isLoaded, isFalse);
      expect(state.isFailure, isFalse);
      expect(state.isActionLoading, isFalse);
      expect(state.isActionSuccess, isFalse);
      expect(state.isActionFailure, isFalse);
      expect(state.hasPlans, isFalse);
      expect(state.hasInvoices, isFalse);
      expect(state.hasCheckoutUrl, isFalse);
      expect(state.hasBillingPortalSession, isFalse);
      expect(state.canOpenBillingPortal, isFalse);
      expect(state.isPremium, isFalse);
      expect(state.canDownload, isFalse);
      expect(state.adsEnabled, isTrue);
      expect(state.currentPlan, isNull);
      expect(state.upgradePlans, isEmpty);
    });

    test('loading factory keeps previous data', () {
      const subscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
      );

      const plans = <Plan>[
        Plan(code: 'FREE', name: 'Free'),
        Plan(code: 'PRO', name: 'Pro'),
      ];

      const invoices = <BillingInvoice>[
        BillingInvoice(invoiceId: 'in_1'),
      ];

      final state = SubscriptionState.loading(
        previousSubscription: subscription,
        previousPlans: plans,
        previousInvoices: invoices,
      );

      expect(state.status, SubscriptionStatus.loading);
      expect(state.subscription, subscription);
      expect(state.plans, plans);
      expect(state.invoices, invoices);

      expect(state.isLoading, isTrue);
      expect(state.isLoaded, isFalse);
      expect(state.isPremium, isTrue);
      expect(state.hasPlans, isTrue);
      expect(state.hasInvoices, isTrue);
    });

    test('loaded factory stores subscription plans and invoices', () {
      const subscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        canDownload: true,
        adsEnabled: false,
      );

      const plans = <Plan>[
        Plan(code: 'FREE', name: 'Free'),
        Plan(code: 'PRO', name: 'Pro'),
      ];

      const invoices = <BillingInvoice>[
        BillingInvoice(invoiceId: 'in_1'),
      ];

      final state = SubscriptionState.loaded(
        subscription: subscription,
        plans: plans,
        invoices: invoices,
      );

      expect(state.status, SubscriptionStatus.loaded);
      expect(state.subscription, subscription);
      expect(state.plans, plans);
      expect(state.invoices, invoices);

      expect(state.isLoaded, isTrue);
      expect(state.isPremium, isTrue);
      expect(state.canDownload, isTrue);
      expect(state.adsEnabled, isFalse);
      expect(state.hasPlans, isTrue);
      expect(state.hasInvoices, isTrue);
    });

    test('failure factory stores error and previous data', () {
      const subscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
      );

      const plans = <Plan>[
        Plan(code: 'PRO', name: 'Pro'),
      ];

      const invoices = <BillingInvoice>[
        BillingInvoice(invoiceId: 'in_1'),
      ];

      final state = SubscriptionState.failure(
        errorMessage: 'Failed to load subscription.',
        previousSubscription: subscription,
        previousPlans: plans,
        previousInvoices: invoices,
      );

      expect(state.status, SubscriptionStatus.failure);
      expect(state.errorMessage, 'Failed to load subscription.');
      expect(state.subscription, subscription);
      expect(state.plans, plans);
      expect(state.invoices, invoices);

      expect(state.isFailure, isTrue);
      expect(state.isLoaded, isFalse);
    });

    test('computed action helpers reflect action status', () {
      expect(
        const SubscriptionState(
          actionStatus: SubscriptionActionStatus.loading,
        ).isActionLoading,
        isTrue,
      );

      expect(
        const SubscriptionState(
          actionStatus: SubscriptionActionStatus.success,
        ).isActionSuccess,
        isTrue,
      );

      expect(
        const SubscriptionState(
          actionStatus: SubscriptionActionStatus.failure,
        ).isActionFailure,
        isTrue,
      );
    });

    test('currentPlan returns matching plan by normalized code', () {
      const state = SubscriptionState(
        subscription: Subscription(
          planCode: 'pro',
          subscriptionType: 'PRO',
          isPremium: true,
        ),
        plans: <Plan>[
          Plan(code: 'FREE', name: 'Free'),
          Plan(code: 'PRO', name: 'Pro'),
        ],
      );

      expect(state.currentPlan, const Plan(code: 'PRO', name: 'Pro'));
    });

    test('currentPlan returns null when no plan matches', () {
      const state = SubscriptionState(
        subscription: Subscription(planCode: 'GO_PLUS'),
        plans: <Plan>[
          Plan(code: 'FREE', name: 'Free'),
          Plan(code: 'PRO', name: 'Pro'),
        ],
      );

      expect(state.currentPlan, isNull);
    });

    test('upgradePlans returns premium plans only', () {
      const state = SubscriptionState(
        plans: <Plan>[
          Plan(code: 'FREE', name: 'Free'),
          Plan(code: 'PRO', name: 'Pro'),
          Plan(code: 'GO_PLUS', name: 'GO+'),
        ],
      );

      expect(
        state.upgradePlans,
        <Plan>[
          Plan(code: 'PRO', name: 'Pro'),
          Plan(code: 'GO_PLUS', name: 'GO+'),
        ],
      );
    });

    test('portal and checkout helpers detect available values', () {
      const state = SubscriptionState(
        checkoutUrl: 'https://checkout.example.com/pro',
        billingPortalSession: BillingPortalSession(
          url: 'https://billing.example.com/session/test',
        ),
      );

      expect(state.hasCheckoutUrl, isTrue);
      expect(state.hasBillingPortalSession, isTrue);
      expect(state.canOpenBillingPortal, isTrue);
    });

    test('copyWith updates selected fields only', () {
      const original = SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: Subscription(
          planCode: 'FREE',
          subscriptionType: 'FREE',
          isPremium: false,
        ),
        plans: <Plan>[
          Plan(code: 'FREE', name: 'Free'),
        ],
      );

      final updated = original.copyWith(
        actionStatus: SubscriptionActionStatus.loading,
        subscription: const Subscription(
          planCode: 'PRO',
          subscriptionType: 'PRO',
          subscriptionStatus: 'ACTIVE',
          isPremium: true,
        ),
      );

      expect(updated.status, SubscriptionStatus.loaded);
      expect(updated.actionStatus, SubscriptionActionStatus.loading);
      expect(updated.subscription.planCode, 'PRO');
      expect(updated.plans, original.plans);
    });

    test('copyWith clears nullable fields', () {
      const original = SubscriptionState(
        billingPortalSession: BillingPortalSession(
          url: 'https://billing.example.com/session/test',
        ),
        checkoutUrl: 'https://checkout.example.com/pro',
        actionMessage: 'Done',
        errorMessage: 'Failed',
        actionErrorMessage: 'Action failed',
      );

      final updated = original.copyWith(
        clearBillingPortalSession: true,
        clearCheckoutUrl: true,
        clearActionMessage: true,
        clearErrorMessage: true,
        clearActionErrorMessage: true,
      );

      expect(updated.billingPortalSession, isNull);
      expect(updated.checkoutUrl, isNull);
      expect(updated.actionMessage, isNull);
      expect(updated.errorMessage, isNull);
      expect(updated.actionErrorMessage, isNull);
    });

    test('supports value equality', () {
      const first = SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: Subscription(
          planCode: 'PRO',
          subscriptionType: 'PRO',
          isPremium: true,
        ),
        plans: <Plan>[
          Plan(code: 'PRO', name: 'Pro'),
        ],
      );

      const second = SubscriptionState(
        status: SubscriptionStatus.loaded,
        subscription: Subscription(
          planCode: 'PRO',
          subscriptionType: 'PRO',
          isPremium: true,
        ),
        plans: <Plan>[
          Plan(code: 'PRO', name: 'Pro'),
        ],
      );

      const third = SubscriptionState(
        status: SubscriptionStatus.failure,
        subscription: Subscription(
          planCode: 'PRO',
          subscriptionType: 'PRO',
          isPremium: true,
        ),
        plans: <Plan>[
          Plan(code: 'PRO', name: 'Pro'),
        ],
      );

      expect(first, second);
      expect(first == third, isFalse);
      expect(first.props, second.props);
    });
  });
}
