import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/premium/data/datasources/subscription_remote_data_source.dart';
import 'package:soundcloud_clone/features/premium/data/repositories/subscription_repository_impl.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_invoice.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_portal_session.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/offline_track_entitlement.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/plan.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';

class MockSubscriptionRemoteDataSource extends Mock
    implements SubscriptionRemoteDataSource {}

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockSubscriptionRemoteDataSource remoteDataSource;
  late SubscriptionRepositoryImpl repository;

  setUp(() {
    remoteDataSource = MockSubscriptionRemoteDataSource();
    repository = SubscriptionRepositoryImpl(remoteDataSource);
  });

  group('SubscriptionRepositoryImpl', () {
    test('throws ArgumentError when dependency is not supported', () {
      expect(
        () => SubscriptionRepositoryImpl(Object()),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts DioClient dependency for compatibility', () {
      final dioClient = MockDioClient();

      expect(
        () => SubscriptionRepositoryImpl(dioClient),
        returnsNormally,
      );
    });

    test('getMySubscription delegates to remote data source', () async {
      const subscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
      );

      when(
        () => remoteDataSource.getMySubscription(),
      ).thenAnswer((_) async => subscription);

      final result = await repository.getMySubscription();

      expect(result, subscription);

      verify(
        () => remoteDataSource.getMySubscription(),
      ).called(1);

      verifyNoMoreInteractions(remoteDataSource);
    });

    test('getPlans delegates to remote data source', () async {
      const plans = <Plan>[
        Plan(code: 'FREE', name: 'Free'),
        Plan(code: 'PRO', name: 'Pro'),
      ];

      when(
        () => remoteDataSource.getPlans(),
      ).thenAnswer((_) async => plans);

      final result = await repository.getPlans();

      expect(result, plans);

      verify(
        () => remoteDataSource.getPlans(),
      ).called(1);

      verifyNoMoreInteractions(remoteDataSource);
    });

    test('createCheckout delegates plan code to remote data source', () async {
      when(
        () => remoteDataSource.createCheckout(planCode: 'PRO'),
      ).thenAnswer((_) async => 'https://checkout.example.com/pro');

      final result = await repository.createCheckout('PRO');

      expect(result, 'https://checkout.example.com/pro');

      verify(
        () => remoteDataSource.createCheckout(planCode: 'PRO'),
      ).called(1);

      verifyNoMoreInteractions(remoteDataSource);
    });

    test('subscribe delegates subscription type to remote data source', () async {
      when(
        () => remoteDataSource.subscribe(subscriptionType: 'PRO'),
      ).thenAnswer((_) async => 'https://subscribe.example.com/pro');

      final result = await repository.subscribe('PRO');

      expect(result, 'https://subscribe.example.com/pro');

      verify(
        () => remoteDataSource.subscribe(subscriptionType: 'PRO'),
      ).called(1);

      verifyNoMoreInteractions(remoteDataSource);
    });

    test('openBillingPortalSession delegates to remote data source', () async {
      const portalSession = BillingPortalSession(
        url: 'https://billing.example.com/session/test',
        sessionId: 'bps_123',
      );

      when(
        () => remoteDataSource.openBillingPortalSession(),
      ).thenAnswer((_) async => portalSession);

      final result = await repository.openBillingPortalSession();

      expect(result, portalSession);

      verify(
        () => remoteDataSource.openBillingPortalSession(),
      ).called(1);

      verifyNoMoreInteractions(remoteDataSource);
    });

    test('openPortal returns launch url from portal session', () async {
      const portalSession = BillingPortalSession(
        url: 'https://billing.example.com/session/test',
        portalUrl: 'https://fallback.example.com/session/test',
        sessionId: 'bps_123',
      );

      when(
        () => remoteDataSource.openBillingPortalSession(),
      ).thenAnswer((_) async => portalSession);

      final result = await repository.openPortal();

      expect(result, 'https://billing.example.com/session/test');

      verify(
        () => remoteDataSource.openBillingPortalSession(),
      ).called(1);

      verifyNoMoreInteractions(remoteDataSource);
    });

    test('getInvoices delegates to remote data source', () async {
      const invoices = <BillingInvoice>[
        BillingInvoice(
          invoiceId: 'in_mock_abc123',
          amountPaidCents: 999,
          status: 'PAID',
        ),
      ];

      when(
        () => remoteDataSource.getInvoices(),
      ).thenAnswer((_) async => invoices);

      final result = await repository.getInvoices();

      expect(result, invoices);

      verify(
        () => remoteDataSource.getInvoices(),
      ).called(1);

      verifyNoMoreInteractions(remoteDataSource);
    });

    test('cancelSubscription posts cancel then refreshes subscription', () async {
      const refreshedSubscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        cancelAtPeriodEnd: true,
        canResume: true,
      );

      when(
        () => remoteDataSource.cancelSubscription(),
      ).thenAnswer((_) async {});

      when(
        () => remoteDataSource.getMySubscription(),
      ).thenAnswer((_) async => refreshedSubscription);

      final result = await repository.cancelSubscription();

      expect(result, refreshedSubscription);
      expect(result.cancelAtPeriodEnd, isTrue);
      expect(result.canResume, isTrue);

      verifyInOrder(<void Function()>[
        () => remoteDataSource.cancelSubscription(),
        () => remoteDataSource.getMySubscription(),
      ]);

      verifyNoMoreInteractions(remoteDataSource);
    });

    test('resumeSubscription delegates to remote data source', () async {
      const resumedSubscription = Subscription(
        planCode: 'PRO',
        subscriptionType: 'PRO',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
        cancelAtPeriodEnd: false,
        canResume: false,
      );

      when(
        () => remoteDataSource.resumeSubscription(),
      ).thenAnswer((_) async => resumedSubscription);

      final result = await repository.resumeSubscription();

      expect(result, resumedSubscription);
      expect(result.cancelAtPeriodEnd, isFalse);
      expect(result.canResume, isFalse);

      verify(
        () => remoteDataSource.resumeSubscription(),
      ).called(1);

      verifyNoMoreInteractions(remoteDataSource);
    });

    test('changePlan delegates plan code to remote data source', () async {
      const changedSubscription = Subscription(
        planCode: 'GO_PLUS',
        subscriptionType: 'GO_PLUS',
        subscriptionStatus: 'ACTIVE',
        isPremium: true,
      );

      when(
        () => remoteDataSource.changePlan(planCode: 'GO_PLUS'),
      ).thenAnswer((_) async => changedSubscription);

      final result = await repository.changePlan('GO_PLUS');

      expect(result, changedSubscription);
      expect(result.planCode, 'GO_PLUS');

      verify(
        () => remoteDataSource.changePlan(planCode: 'GO_PLUS'),
      ).called(1);

      verifyNoMoreInteractions(remoteDataSource);
    });

    test('getOfflineTrackEntitlement delegates track id to remote data source',
        () async {
      const entitlement = OfflineTrackEntitlement(
        trackId: 'track-1',
        title: 'Midnight Drive',
        planCode: 'PRO',
      );

      when(
        () => remoteDataSource.getOfflineTrackEntitlement(trackId: 'track-1'),
      ).thenAnswer((_) async => entitlement);

      final result = await repository.getOfflineTrackEntitlement('track-1');

      expect(result, entitlement);
      expect(result.trackId, 'track-1');
      expect(result.title, 'Midnight Drive');

      verify(
        () => remoteDataSource.getOfflineTrackEntitlement(trackId: 'track-1'),
      ).called(1);

      verifyNoMoreInteractions(remoteDataSource);
    });

    test('propagates remote data source exceptions', () async {
      final exception = Exception('Network error');

      when(
        () => remoteDataSource.getMySubscription(),
      ).thenThrow(exception);

      expect(
        () => repository.getMySubscription(),
        throwsA(same(exception)),
      );

      verify(
        () => remoteDataSource.getMySubscription(),
      ).called(1);

      verifyNoMoreInteractions(remoteDataSource);
    });
  });
}