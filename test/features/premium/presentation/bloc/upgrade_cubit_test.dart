import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/features/premium/domain/entities/billing_invoice.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_portal_session.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/plan.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_state.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

void main() {
  late MockSubscriptionRepository repository;

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
    canResume: true,
  );

  const goPlusSubscription = Subscription(
    userId: 'user-1',
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
    uploadedTracks: 5,
    remainingUploads: 995,
  );

  const invoice = BillingInvoice(
    invoiceId: 'in_mock_abc123',
    amountPaidCents: 999,
    status: 'PAID',
    planName: 'Pro',
    planTier: 'PRO',
  );

  const portalSession = BillingPortalSession(
    url: 'https://billing.example.com/session/test',
    sessionId: 'bps_123',
    canUpdatePaymentMethod: true,
    canCancel: true,
    canChangePlan: true,
  );

  setUp(() {
    repository = MockSubscriptionRepository();
  });

  group('SubscriptionCubit', () {
    test('initial state is SubscriptionState.initial', () {
      final cubit = SubscriptionCubit(repository);

      expect(cubit.state, SubscriptionState.initial());

      cubit.close();
    });

    blocTest<SubscriptionCubit, SubscriptionState>(
      'loadSubscription emits loading then loaded with subscription and plans',
      build: () {
        when(
          () => repository.getMySubscription(),
        ).thenAnswer((_) async => proSubscription);

        when(
          () => repository.getPlans(),
        ).thenAnswer((_) async => const <Plan>[freePlan, proPlan]);

        return SubscriptionCubit(repository);
      },
      act: (cubit) => cubit.loadSubscription(),
      expect: () => <SubscriptionState>[
        SubscriptionState.loading(),
        SubscriptionState.loaded(
          subscription: proSubscription,
          plans: const <Plan>[freePlan, proPlan],
        ),
      ],
      verify: (_) {
        verify(
          () => repository.getMySubscription(),
        ).called(1);

        verify(
          () => repository.getPlans(),
        ).called(1);

        verifyNoMoreInteractions(repository);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'loadSubscription emits failure and preserves previous data on error',
      build: () {
        when(
          () => repository.getMySubscription(),
        ).thenThrow(Exception('Network error'));

        return SubscriptionCubit(repository);
      },
      seed: () => SubscriptionState.loaded(
        subscription: proSubscription,
        plans: const <Plan>[freePlan, proPlan],
        invoices: const <BillingInvoice>[invoice],
      ),
      act: (cubit) => cubit.loadSubscription(),
      expect: () => <SubscriptionState>[
        SubscriptionState.loading(
          previousSubscription: proSubscription,
          previousPlans: const <Plan>[freePlan, proPlan],
          previousInvoices: const <BillingInvoice>[invoice],
        ),
        SubscriptionState.failure(
          errorMessage: 'Network error',
          previousSubscription: proSubscription,
          previousPlans: const <Plan>[freePlan, proPlan],
          previousInvoices: const <BillingInvoice>[invoice],
        ),
      ],
      verify: (_) {
        verify(
          () => repository.getMySubscription(),
        ).called(1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'loadBilling emits action loading then success with invoices',
      build: () {
        when(
          () => repository.getMySubscription(),
        ).thenAnswer((_) async => proSubscription);

        when(
          () => repository.getInvoices(),
        ).thenAnswer((_) async => const <BillingInvoice>[invoice]);

        return SubscriptionCubit(repository);
      },
      seed: () => SubscriptionState.loaded(
        subscription: proSubscription,
        plans: const <Plan>[freePlan, proPlan],
      ),
      act: (cubit) => cubit.loadBilling(),
      expect: () => <SubscriptionState>[
        SubscriptionState.loaded(
          subscription: proSubscription,
          plans: const <Plan>[freePlan, proPlan],
        ).copyWith(
          actionStatus: SubscriptionActionStatus.loading,
          clearActionMessage: true,
          clearActionErrorMessage: true,
        ),
        SubscriptionState.loaded(
          subscription: proSubscription,
          plans: const <Plan>[freePlan, proPlan],
          invoices: const <BillingInvoice>[invoice],
        ).copyWith(
          actionStatus: SubscriptionActionStatus.success,
          actionMessage: 'Billing details loaded.',
          clearErrorMessage: true,
          clearActionErrorMessage: true,
        ),
      ],
      verify: (_) {
        verify(
          () => repository.getMySubscription(),
        ).called(1);

        verify(
          () => repository.getInvoices(),
        ).called(1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'loadBilling emits action failure on error',
      build: () {
        when(
          () => repository.getMySubscription(),
        ).thenThrow(Exception('Billing failed'));

        return SubscriptionCubit(repository);
      },
      seed: () => SubscriptionState.loaded(
        subscription: proSubscription,
        plans: const <Plan>[freePlan, proPlan],
      ),
      act: (cubit) => cubit.loadBilling(),
      expect: () => <SubscriptionState>[
        SubscriptionState.loaded(
          subscription: proSubscription,
          plans: const <Plan>[freePlan, proPlan],
        ).copyWith(
          actionStatus: SubscriptionActionStatus.loading,
          clearActionMessage: true,
          clearActionErrorMessage: true,
        ),
        SubscriptionState.loaded(
          subscription: proSubscription,
          plans: const <Plan>[freePlan, proPlan],
        ).copyWith(
          actionStatus: SubscriptionActionStatus.failure,
          actionErrorMessage: 'Billing failed',
          clearActionMessage: true,
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'upgrade emits checkout success and returns checkout url',
      build: () {
        when(
          () => repository.createCheckout('PRO'),
        ).thenAnswer((_) async => 'https://checkout.example.com/pro');

        return SubscriptionCubit(repository);
      },
      seed: () => SubscriptionState.loaded(
        subscription: const Subscription(),
        plans: const <Plan>[freePlan, proPlan],
      ),
      act: (cubit) async {
        final url = await cubit.upgrade('PRO');
        expect(url, 'https://checkout.example.com/pro');
      },
      expect: () => <SubscriptionState>[
        SubscriptionState.loaded(
          subscription: const Subscription(),
          plans: const <Plan>[freePlan, proPlan],
        ).copyWith(
          actionStatus: SubscriptionActionStatus.loading,
          clearCheckoutUrl: true,
          clearActionMessage: true,
          clearActionErrorMessage: true,
        ),
        SubscriptionState.loaded(
          subscription: const Subscription(),
          plans: const <Plan>[freePlan, proPlan],
        ).copyWith(
          actionStatus: SubscriptionActionStatus.success,
          checkoutUrl: 'https://checkout.example.com/pro',
          actionMessage: 'Checkout session created.',
          clearActionErrorMessage: true,
        ),
      ],
      verify: (_) {
        verify(
          () => repository.createCheckout('PRO'),
        ).called(1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'upgrade emits action failure and rethrows on error',
      build: () {
        when(
          () => repository.createCheckout('PRO'),
        ).thenThrow(Exception('Checkout failed'));

        return SubscriptionCubit(repository);
      },
      seed: () => SubscriptionState.loaded(
        subscription: const Subscription(),
        plans: const <Plan>[freePlan, proPlan],
      ),
      act: (cubit) async {
        expect(
          () => cubit.upgrade('PRO'),
          throwsA(isA<Exception>()),
        );
      },
      expect: () => <SubscriptionState>[
        SubscriptionState.loaded(
          subscription: const Subscription(),
          plans: const <Plan>[freePlan, proPlan],
        ).copyWith(
          actionStatus: SubscriptionActionStatus.loading,
          clearCheckoutUrl: true,
          clearActionMessage: true,
          clearActionErrorMessage: true,
        ),
        SubscriptionState.loaded(
          subscription: const Subscription(),
          plans: const <Plan>[freePlan, proPlan],
        ).copyWith(
          actionStatus: SubscriptionActionStatus.failure,
          actionErrorMessage: 'Checkout failed',
          clearCheckoutUrl: true,
          clearActionMessage: true,
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'subscribe emits redirect success and returns redirect url',
      build: () {
        when(
          () => repository.subscribe('PRO'),
        ).thenAnswer((_) async => 'https://subscribe.example.com/pro');

        return SubscriptionCubit(repository);
      },
      act: (cubit) async {
        final url = await cubit.subscribe('PRO');
        expect(url, 'https://subscribe.example.com/pro');
      },
      expect: () => <SubscriptionState>[
        SubscriptionState.initial().copyWith(
          actionStatus: SubscriptionActionStatus.loading,
          clearCheckoutUrl: true,
          clearActionMessage: true,
          clearActionErrorMessage: true,
        ),
        SubscriptionState.initial().copyWith(
          actionStatus: SubscriptionActionStatus.success,
          checkoutUrl: 'https://subscribe.example.com/pro',
          actionMessage: 'Subscription request created.',
          clearActionErrorMessage: true,
        ),
      ],
      verify: (_) {
        verify(
          () => repository.subscribe('PRO'),
        ).called(1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'cancel emits action loading then success with refreshed subscription',
      build: () {
        when(
          () => repository.cancelSubscription(),
        ).thenAnswer((_) async => cancelingSubscription);

        return SubscriptionCubit(repository);
      },
      seed: () => SubscriptionState.loaded(
        subscription: proSubscription,
        plans: const <Plan>[freePlan, proPlan],
      ),
      act: (cubit) => cubit.cancel(),
      expect: () => <SubscriptionState>[
        SubscriptionState.loaded(
          subscription: proSubscription,
          plans: const <Plan>[freePlan, proPlan],
        ).copyWith(
          actionStatus: SubscriptionActionStatus.loading,
          clearActionMessage: true,
          clearActionErrorMessage: true,
        ),
        SubscriptionState.loaded(
          subscription: cancelingSubscription,
          plans: const <Plan>[freePlan, proPlan],
        ).copyWith(
          actionStatus: SubscriptionActionStatus.success,
          actionMessage: 'Subscription cancellation scheduled.',
          clearActionErrorMessage: true,
        ),
      ],
      verify: (_) {
        verify(
          () => repository.cancelSubscription(),
        ).called(1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'cancel emits action failure on error',
      build: () {
        when(
          () => repository.cancelSubscription(),
        ).thenThrow(Exception('Cancel failed'));

        return SubscriptionCubit(repository);
      },
      seed: () => SubscriptionState.loaded(subscription: proSubscription),
      act: (cubit) => cubit.cancel(),
      expect: () => <SubscriptionState>[
        SubscriptionState.loaded(subscription: proSubscription).copyWith(
          actionStatus: SubscriptionActionStatus.loading,
          clearActionMessage: true,
          clearActionErrorMessage: true,
        ),
        SubscriptionState.loaded(subscription: proSubscription).copyWith(
          actionStatus: SubscriptionActionStatus.failure,
          actionErrorMessage: 'Cancel failed',
          clearActionMessage: true,
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'resume emits action loading then success with resumed subscription',
      build: () {
        when(
          () => repository.resumeSubscription(),
        ).thenAnswer((_) async => proSubscription);

        return SubscriptionCubit(repository);
      },
      seed: () => SubscriptionState.loaded(subscription: cancelingSubscription),
      act: (cubit) => cubit.resume(),
      expect: () => <SubscriptionState>[
        SubscriptionState.loaded(subscription: cancelingSubscription).copyWith(
          actionStatus: SubscriptionActionStatus.loading,
          clearActionMessage: true,
          clearActionErrorMessage: true,
        ),
        SubscriptionState.loaded(subscription: proSubscription).copyWith(
          actionStatus: SubscriptionActionStatus.success,
          actionMessage: 'Subscription resumed.',
          clearActionErrorMessage: true,
        ),
      ],
      verify: (_) {
        verify(
          () => repository.resumeSubscription(),
        ).called(1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'changePlan emits action loading then success with changed subscription',
      build: () {
        when(
          () => repository.changePlan('GO_PLUS'),
        ).thenAnswer((_) async => goPlusSubscription);

        return SubscriptionCubit(repository);
      },
      seed: () => SubscriptionState.loaded(
        subscription: proSubscription,
        plans: const <Plan>[freePlan, proPlan],
      ),
      act: (cubit) => cubit.changePlan('GO_PLUS'),
      expect: () => <SubscriptionState>[
        SubscriptionState.loaded(
          subscription: proSubscription,
          plans: const <Plan>[freePlan, proPlan],
        ).copyWith(
          actionStatus: SubscriptionActionStatus.loading,
          clearActionMessage: true,
          clearActionErrorMessage: true,
        ),
        SubscriptionState.loaded(
          subscription: goPlusSubscription,
          plans: const <Plan>[freePlan, proPlan],
        ).copyWith(
          actionStatus: SubscriptionActionStatus.success,
          actionMessage: 'Subscription plan changed.',
          clearActionErrorMessage: true,
        ),
      ],
      verify: (_) {
        verify(
          () => repository.changePlan('GO_PLUS'),
        ).called(1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'openBillingPortal emits success and returns launch url',
      build: () {
        when(
          () => repository.openBillingPortalSession(),
        ).thenAnswer((_) async => portalSession);

        return SubscriptionCubit(repository);
      },
      seed: () => SubscriptionState.loaded(subscription: proSubscription),
      act: (cubit) async {
        final url = await cubit.openBillingPortal();
        expect(url, 'https://billing.example.com/session/test');
      },
      expect: () => <SubscriptionState>[
        SubscriptionState.loaded(subscription: proSubscription).copyWith(
          actionStatus: SubscriptionActionStatus.loading,
          clearBillingPortalSession: true,
          clearActionMessage: true,
          clearActionErrorMessage: true,
        ),
        SubscriptionState.loaded(subscription: proSubscription).copyWith(
          actionStatus: SubscriptionActionStatus.success,
          billingPortalSession: portalSession,
          actionMessage: 'Billing portal opened.',
          clearActionErrorMessage: true,
        ),
      ],
      verify: (_) {
        verify(
          () => repository.openBillingPortalSession(),
        ).called(1);
      },
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'openBillingPortal emits failure and rethrows on error',
      build: () {
        when(
          () => repository.openBillingPortalSession(),
        ).thenThrow(Exception('Portal failed'));

        return SubscriptionCubit(repository);
      },
      seed: () => SubscriptionState.loaded(subscription: proSubscription),
      act: (cubit) async {
        expect(
          () => cubit.openBillingPortal(),
          throwsA(isA<Exception>()),
        );
      },
      expect: () => <SubscriptionState>[
        SubscriptionState.loaded(subscription: proSubscription).copyWith(
          actionStatus: SubscriptionActionStatus.loading,
          clearBillingPortalSession: true,
          clearActionMessage: true,
          clearActionErrorMessage: true,
        ),
        SubscriptionState.loaded(subscription: proSubscription).copyWith(
          actionStatus: SubscriptionActionStatus.failure,
          actionErrorMessage: 'Portal failed',
          clearBillingPortalSession: true,
          clearActionMessage: true,
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'refreshAfterPayment delegates to loadSubscription',
      build: () {
        when(
          () => repository.getMySubscription(),
        ).thenAnswer((_) async => proSubscription);

        when(
          () => repository.getPlans(),
        ).thenAnswer((_) async => const <Plan>[freePlan, proPlan]);

        return SubscriptionCubit(repository);
      },
      act: (cubit) => cubit.refreshAfterPayment(),
      expect: () => <SubscriptionState>[
        SubscriptionState.loading(),
        SubscriptionState.loaded(
          subscription: proSubscription,
          plans: const <Plan>[freePlan, proPlan],
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'clearActionStatus resets action status and messages',
      build: () => SubscriptionCubit(repository),
      seed: () => SubscriptionState.loaded(
        subscription: proSubscription,
      ).copyWith(
        actionStatus: SubscriptionActionStatus.failure,
        actionErrorMessage: 'Failed',
        actionMessage: 'Done',
      ),
      act: (cubit) => cubit.clearActionStatus(),
      expect: () => <SubscriptionState>[
        SubscriptionState.loaded(subscription: proSubscription).copyWith(
          actionStatus: SubscriptionActionStatus.idle,
          clearActionMessage: true,
          clearActionErrorMessage: true,
        ),
      ],
    );

    blocTest<SubscriptionCubit, SubscriptionState>(
      'clearCheckoutUrl clears checkout url only',
      build: () => SubscriptionCubit(repository),
      seed: () => SubscriptionState.loaded(
        subscription: proSubscription,
      ).copyWith(
        checkoutUrl: 'https://checkout.example.com/pro',
        actionStatus: SubscriptionActionStatus.success,
      ),
      act: (cubit) => cubit.clearCheckoutUrl(),
      expect: () => <SubscriptionState>[
        SubscriptionState.loaded(subscription: proSubscription).copyWith(
          actionStatus: SubscriptionActionStatus.success,
          clearCheckoutUrl: true,
        ),
      ],
    );
  });
}