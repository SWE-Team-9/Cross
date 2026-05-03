import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/offline/data/repositories/offline_repository.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/premium/data/datasources/subscription_remote_data_source.dart';
import 'package:soundcloud_clone/features/premium/data/repositories/subscription_repository_impl.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_invoice.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_portal_session.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/offline_track_entitlement.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/plan.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/domain/usecases/subscription_usecases.dart';
import 'package:soundcloud_clone/features/premium/premium_di.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/upload/domain/usecases/check_upload_limit_usecase.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late GetIt getIt;
  late MockDioClient dioClient;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    getIt = GetIt.asNewInstance();
    dioClient = MockDioClient();

    getIt.registerSingleton<DioClient>(dioClient);
  });

  tearDown(() async {
    if (getIt.isRegistered<OfflineCubit>()) {
      final offlineCubit = getIt<OfflineCubit>();
      await offlineCubit.close();
    }

    await getIt.reset();
  });

  group('registerPremiumDependencies', () {
    test('registers premium data layer dependencies', () {
      registerPremiumDependencies(getIt);

      expect(getIt.isRegistered<SubscriptionRemoteDataSource>(), isTrue);
      expect(getIt.isRegistered<SubscriptionRepository>(), isTrue);

      expect(
        getIt<SubscriptionRemoteDataSource>(),
        isA<SubscriptionRemoteDataSourceImpl>(),
      );

      expect(
        getIt<SubscriptionRepository>(),
        isA<SubscriptionRepositoryImpl>(),
      );
    });

    test('registers subscription use cases', () {
      registerPremiumDependencies(getIt);

      expect(getIt.isRegistered<GetMySubscriptionUseCase>(), isTrue);
      expect(getIt.isRegistered<GetSubscriptionPlansUseCase>(), isTrue);
      expect(getIt.isRegistered<CreateCheckoutUseCase>(), isTrue);
      expect(getIt.isRegistered<SubscribeUseCase>(), isTrue);
      expect(getIt.isRegistered<OpenBillingPortalUseCase>(), isTrue);
      expect(getIt.isRegistered<OpenBillingPortalUrlUseCase>(), isTrue);
      expect(getIt.isRegistered<GetBillingInvoicesUseCase>(), isTrue);
      expect(getIt.isRegistered<CancelSubscriptionUseCase>(), isTrue);
      expect(getIt.isRegistered<ResumeSubscriptionUseCase>(), isTrue);
      expect(getIt.isRegistered<ChangeSubscriptionPlanUseCase>(), isTrue);
      expect(getIt.isRegistered<GetOfflineTrackEntitlementUseCase>(), isTrue);

      expect(
          getIt<GetMySubscriptionUseCase>(), isA<GetMySubscriptionUseCase>());
      expect(
        getIt<GetSubscriptionPlansUseCase>(),
        isA<GetSubscriptionPlansUseCase>(),
      );
      expect(getIt<CreateCheckoutUseCase>(), isA<CreateCheckoutUseCase>());
      expect(getIt<SubscribeUseCase>(), isA<SubscribeUseCase>());
      expect(
        getIt<OpenBillingPortalUseCase>(),
        isA<OpenBillingPortalUseCase>(),
      );
      expect(
        getIt<OpenBillingPortalUrlUseCase>(),
        isA<OpenBillingPortalUrlUseCase>(),
      );
      expect(
        getIt<GetBillingInvoicesUseCase>(),
        isA<GetBillingInvoicesUseCase>(),
      );
      expect(
        getIt<CancelSubscriptionUseCase>(),
        isA<CancelSubscriptionUseCase>(),
      );
      expect(
        getIt<ResumeSubscriptionUseCase>(),
        isA<ResumeSubscriptionUseCase>(),
      );
      expect(
        getIt<ChangeSubscriptionPlanUseCase>(),
        isA<ChangeSubscriptionPlanUseCase>(),
      );
      expect(
        getIt<GetOfflineTrackEntitlementUseCase>(),
        isA<GetOfflineTrackEntitlementUseCase>(),
      );
    });

    test('registers upload limit use case', () {
      registerPremiumDependencies(getIt);

      expect(getIt.isRegistered<CheckUploadLimitUseCase>(), isTrue);
      expect(
        getIt<CheckUploadLimitUseCase>(),
        isA<CheckUploadLimitUseCase>(),
      );
    });

    test('registers subscription cubit as factory', () async {
      registerPremiumDependencies(getIt);

      expect(getIt.isRegistered<SubscriptionCubit>(), isTrue);

      final firstCubit = getIt<SubscriptionCubit>();
      final secondCubit = getIt<SubscriptionCubit>();

      expect(firstCubit, isA<SubscriptionCubit>());
      expect(secondCubit, isA<SubscriptionCubit>());
      expect(identical(firstCubit, secondCubit), isFalse);

      await firstCubit.close();
      await secondCubit.close();
    });

    test('registers offline repository and offline cubit', () {
      registerPremiumDependencies(getIt);

      expect(getIt.isRegistered<OfflineRepository>(), isTrue);
      expect(getIt.isRegistered<OfflineCubit>(), isTrue);

      expect(getIt<OfflineRepository>(), isA<OfflineRepository>());
      expect(getIt<OfflineCubit>(), isA<OfflineCubit>());
    });

    test('is idempotent when called more than once', () {
      registerPremiumDependencies(getIt);
      registerPremiumDependencies(getIt);

      expect(getIt.isRegistered<SubscriptionRemoteDataSource>(), isTrue);
      expect(getIt.isRegistered<SubscriptionRepository>(), isTrue);
      expect(getIt.isRegistered<SubscriptionCubit>(), isTrue);
      expect(getIt.isRegistered<OfflineRepository>(), isTrue);
      expect(getIt.isRegistered<OfflineCubit>(), isTrue);
      expect(getIt.isRegistered<CheckUploadLimitUseCase>(), isTrue);
    });

    test('does not override pre-registered subscription repository', () {
      final fakeRepository = _FakeSubscriptionRepository();

      getIt.registerSingleton<SubscriptionRepository>(fakeRepository);

      registerPremiumDependencies(getIt);

      expect(getIt<SubscriptionRepository>(), same(fakeRepository));
      expect(
          getIt<GetMySubscriptionUseCase>(), isA<GetMySubscriptionUseCase>());
      expect(getIt<SubscriptionCubit>(), isA<SubscriptionCubit>());
    });

    test('does not override pre-registered upload limit use case', () {
      const existingUseCase = CheckUploadLimitUseCase();

      getIt.registerSingleton<CheckUploadLimitUseCase>(existingUseCase);

      registerPremiumDependencies(getIt);

      expect(getIt<CheckUploadLimitUseCase>(), same(existingUseCase));
    });
  });
}

class _FakeSubscriptionRepository extends SubscriptionRepository {
  @override
  Future<Subscription> getMySubscription() async {
    return const Subscription(
      planCode: 'PRO',
      subscriptionType: 'PRO',
      subscriptionStatus: 'ACTIVE',
      isPremium: true,
    );
  }

  @override
  Future<List<Plan>> getPlans() async {
    return const <Plan>[
      Plan(code: 'FREE', name: 'Free'),
      Plan(code: 'PRO', name: 'Pro'),
    ];
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
    return const BillingPortalSession(
      url: 'https://billing.example.com/session/test',
      sessionId: 'bps_123',
    );
  }

  @override
  Future<List<BillingInvoice>> getInvoices() async {
    return const <BillingInvoice>[];
  }

  @override
  Future<Subscription> cancelSubscription() async {
    return const Subscription(
      planCode: 'PRO',
      subscriptionType: 'PRO',
      subscriptionStatus: 'ACTIVE',
      isPremium: true,
      cancelAtPeriodEnd: true,
      canResume: true,
    );
  }

  @override
  Future<Subscription> resumeSubscription() async {
    return const Subscription(
      planCode: 'PRO',
      subscriptionType: 'PRO',
      subscriptionStatus: 'ACTIVE',
      isPremium: true,
      cancelAtPeriodEnd: false,
      canResume: false,
    );
  }

  @override
  Future<Subscription> changePlan(String plan) async {
    return Subscription(
      planCode: plan,
      subscriptionType: plan,
      subscriptionStatus: 'ACTIVE',
      isPremium: plan.trim().toUpperCase() != 'FREE',
    );
  }

  @override
  Future<Subscription> cancelPlanChange() async {
    return const Subscription(
      planCode: 'PRO',
      subscriptionType: 'PRO',
      subscriptionStatus: 'ACTIVE',
      isPremium: true,
    );
  }

  @override
  Future<OfflineTrackEntitlement> getOfflineTrackEntitlement(
    String trackId,
  ) async {
    return OfflineTrackEntitlement(
      trackId: trackId,
      planCode: 'PRO',
    );
  }
}
