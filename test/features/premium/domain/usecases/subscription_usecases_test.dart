import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/features/premium/domain/entities/billing_invoice.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_portal_session.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/offline_track_entitlement.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/plan.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/domain/usecases/subscription_usecases.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

void main() {
  late MockSubscriptionRepository repository;

  setUp(() {
    repository = MockSubscriptionRepository();
  });

  group('GetMySubscriptionUseCase', () {
    test('delegates to repository', () async {
      const subscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
      );

      when(
        () => repository.getMySubscription(),
      ).thenAnswer((_) async => subscription);

      final useCase = GetMySubscriptionUseCase(repository);
      final result = await useCase();

      expect(result, subscription);

      verify(
        () => repository.getMySubscription(),
      ).called(1);

      verifyNoMoreInteractions(repository);
    });
  });

  group('GetSubscriptionPlansUseCase', () {
    test('delegates to repository', () async {
      const plans = <Plan>[
        Plan(code: 'FREE', name: 'Free'),
        Plan(code: 'PRO', name: 'Pro'),
      ];

      when(
        () => repository.getPlans(),
      ).thenAnswer((_) async => plans);

      final useCase = GetSubscriptionPlansUseCase(repository);
      final result = await useCase();

      expect(result, plans);

      verify(
        () => repository.getPlans(),
      ).called(1);

      verifyNoMoreInteractions(repository);
    });
  });

  group('CreateCheckoutUseCase', () {
    test('delegates plan code to repository', () async {
      when(
        () => repository.createCheckout('PRO'),
      ).thenAnswer((_) async => 'https://checkout.example.com/pro');

      final useCase = CreateCheckoutUseCase(repository);
      final result = await useCase('PRO');

      expect(result, 'https://checkout.example.com/pro');

      verify(
        () => repository.createCheckout('PRO'),
      ).called(1);

      verifyNoMoreInteractions(repository);
    });
  });

  group('SubscribeUseCase', () {
    test('delegates plan code to repository', () async {
      when(
        () => repository.subscribe('PRO'),
      ).thenAnswer((_) async => 'https://subscribe.example.com/pro');

      final useCase = SubscribeUseCase(repository);
      final result = await useCase('PRO');

      expect(result, 'https://subscribe.example.com/pro');

      verify(
        () => repository.subscribe('PRO'),
      ).called(1);

      verifyNoMoreInteractions(repository);
    });
  });

  group('OpenBillingPortalUseCase', () {
    test('delegates to repository', () async {
      const session = BillingPortalSession(
        url: 'https://billing.example.com/session/test',
        sessionId: 'bps_123',
      );

      when(
        () => repository.openBillingPortalSession(),
      ).thenAnswer((_) async => session);

      final useCase = OpenBillingPortalUseCase(repository);
      final result = await useCase();

      expect(result, session);

      verify(
        () => repository.openBillingPortalSession(),
      ).called(1);

      verifyNoMoreInteractions(repository);
    });
  });

  group('OpenBillingPortalUrlUseCase', () {
    test('delegates to repository legacy portal url method', () async {
      when(
        () => repository.openPortal(),
      ).thenAnswer((_) async => 'https://billing.example.com/session/test');

      final useCase = OpenBillingPortalUrlUseCase(repository);
      final result = await useCase();

      expect(result, 'https://billing.example.com/session/test');

      verify(
        () => repository.openPortal(),
      ).called(1);

      verifyNoMoreInteractions(repository);
    });
  });

  group('GetBillingInvoicesUseCase', () {
    test('delegates to repository', () async {
      const invoices = <BillingInvoice>[
        BillingInvoice(
          invoiceId: 'in_mock_abc123',
          amountPaidCents: 999,
          status: 'PAID',
        ),
      ];

      when(
        () => repository.getInvoices(),
      ).thenAnswer((_) async => invoices);

      final useCase = GetBillingInvoicesUseCase(repository);
      final result = await useCase();

      expect(result, invoices);

      verify(
        () => repository.getInvoices(),
      ).called(1);

      verifyNoMoreInteractions(repository);
    });
  });

  group('CancelSubscriptionUseCase', () {
    test('delegates to repository', () async {
      const subscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        cancelAtPeriodEnd: true,
        canResume: true,
      );

      when(
        () => repository.cancelSubscription(),
      ).thenAnswer((_) async => subscription);

      final useCase = CancelSubscriptionUseCase(repository);
      final result = await useCase();

      expect(result, subscription);
      expect(result.cancelAtPeriodEnd, isTrue);
      expect(result.canResume, isTrue);

      verify(
        () => repository.cancelSubscription(),
      ).called(1);

      verifyNoMoreInteractions(repository);
    });
  });

  group('ResumeSubscriptionUseCase', () {
    test('delegates to repository', () async {
      const subscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        cancelAtPeriodEnd: false,
        canResume: false,
      );

      when(
        () => repository.resumeSubscription(),
      ).thenAnswer((_) async => subscription);

      final useCase = ResumeSubscriptionUseCase(repository);
      final result = await useCase();

      expect(result, subscription);
      expect(result.cancelAtPeriodEnd, isFalse);
      expect(result.canResume, isFalse);

      verify(
        () => repository.resumeSubscription(),
      ).called(1);

      verifyNoMoreInteractions(repository);
    });
  });

  group('ChangeSubscriptionPlanUseCase', () {
    test('delegates plan code to repository', () async {
      const subscription = Subscription(
        planCode: 'GO_PLUS',
        subscriptionType: 'GO_PLUS',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
      );

      when(
        () => repository.changePlan('GO_PLUS'),
      ).thenAnswer((_) async => subscription);

      final useCase = ChangeSubscriptionPlanUseCase(repository);
      final result = await useCase('GO_PLUS');

      expect(result, subscription);
      expect(result.planCode, 'GO_PLUS');

      verify(
        () => repository.changePlan('GO_PLUS'),
      ).called(1);

      verifyNoMoreInteractions(repository);
    });
  });

  group('GetOfflineTrackEntitlementUseCase', () {
    test('delegates track id to repository', () async {
      const entitlement = OfflineTrackEntitlement(
        trackId: 'track-1',
        title: 'Midnight Drive',
        planCode: 'PRO',
      );

      when(
        () => repository.getOfflineTrackEntitlement('track-1'),
      ).thenAnswer((_) async => entitlement);

      final useCase = GetOfflineTrackEntitlementUseCase(repository);
      final result = await useCase('track-1');

      expect(result, entitlement);
      expect(result.trackId, 'track-1');
      expect(result.title, 'Midnight Drive');

      verify(
        () => repository.getOfflineTrackEntitlement('track-1'),
      ).called(1);

      verifyNoMoreInteractions(repository);
    });
  });

  test('propagates repository exceptions', () async {
    final exception = Exception('Network error');

    when(
      () => repository.getMySubscription(),
    ).thenThrow(exception);

    final useCase = GetMySubscriptionUseCase(repository);

    expect(
      () => useCase(),
      throwsA(same(exception)),
    );

    verify(
      () => repository.getMySubscription(),
    ).called(1);

    verifyNoMoreInteractions(repository);
  });
}