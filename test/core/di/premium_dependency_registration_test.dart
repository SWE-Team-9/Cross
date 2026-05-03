import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('premium dependency registration', () {
    late String injectorSource;
    late String mainSource;

    setUpAll(() {
      injectorSource = File('lib/core/di/injector.dart').readAsStringSync();
      mainSource = File('lib/main.dart').readAsStringSync();
    });

    test('core injector imports premium dependency module', () {
      expect(
        injectorSource,
        contains(
          "import 'package:soundcloud_clone/features/premium/premium_di.dart';",
        ),
      );
    });

    test('setupDependencies registers premium dependencies once', () {
      expect(
        RegExp(r'registerPremiumDependencies\(getIt\);')
            .allMatches(injectorSource)
            .length,
        1,
      );
    });

    test('premium dependencies are registered after DioClient is available',
        () {
      final dioRegistrationIndex = injectorSource.indexOf(
        'getIt.registerLazySingleton<DioClient>',
      );
      final premiumRegistrationIndex = injectorSource.indexOf(
        'registerPremiumDependencies(getIt);',
      );

      expect(dioRegistrationIndex, isNonNegative);
      expect(premiumRegistrationIndex, isNonNegative);
      expect(dioRegistrationIndex, lessThan(premiumRegistrationIndex));
    });

    test(
        'upload picker cubit receives subscription repository and quota usecase',
        () {
      expect(
        injectorSource,
        contains('getIt<SubscriptionRepository>()'),
      );
      expect(
        injectorSource,
        contains('getIt<CheckUploadLimitUseCase>()'),
      );
      expect(
        injectorSource,
        contains('UploadPickerCubit('),
      );
    });

    test('premium module registers subscription remote data source', () {
      final premiumSource = File(
        'lib/features/premium/premium_di.dart',
      ).readAsStringSync();

      expect(
        premiumSource,
        contains('SubscriptionRemoteDataSource'),
      );
      expect(
        premiumSource,
        contains('SubscriptionRemoteDataSourceImpl(getIt<DioClient>())'),
      );
    });

    test('premium module registers subscription repository', () {
      final premiumSource = File(
        'lib/features/premium/premium_di.dart',
      ).readAsStringSync();

      expect(
        premiumSource,
        contains('SubscriptionRepository'),
      );
      expect(
        premiumSource,
        contains('SubscriptionRepositoryImpl('),
      );
    });

    test('premium module registers subscription cubit', () {
      final premiumSource = File(
        'lib/features/premium/premium_di.dart',
      ).readAsStringSync();

      expect(
        premiumSource,
        contains('getIt.registerFactory<SubscriptionCubit>'),
      );
      expect(
        premiumSource,
        contains('SubscriptionCubit(getIt<SubscriptionRepository>())'),
      );
    });

    test('premium module registers offline dependencies', () {
      final premiumSource = File(
        'lib/features/premium/premium_di.dart',
      ).readAsStringSync();

      expect(
        premiumSource,
        contains('getIt.registerLazySingleton<OfflineRepository>'),
      );
      expect(
        premiumSource,
        contains('OfflineRepository(getIt<DioClient>())'),
      );
      expect(
        premiumSource,
        contains('getIt.registerLazySingleton<OfflineCubit>'),
      );
      expect(
        premiumSource,
        contains('OfflineCubit(getIt<OfflineRepository>())'),
      );
    });

    test('premium module registers billing and entitlement use cases', () {
      final premiumSource = File(
        'lib/features/premium/premium_di.dart',
      ).readAsStringSync();

      expect(premiumSource, contains('GetMySubscriptionUseCase'));
      expect(premiumSource, contains('GetSubscriptionPlansUseCase'));
      expect(premiumSource, contains('CreateCheckoutUseCase'));
      expect(premiumSource, contains('SubscribeUseCase'));
      expect(premiumSource, contains('OpenBillingPortalUseCase'));
      expect(premiumSource, contains('GetBillingInvoicesUseCase'));
      expect(premiumSource, contains('CancelSubscriptionUseCase'));
      expect(premiumSource, contains('ResumeSubscriptionUseCase'));
      expect(premiumSource, contains('ChangeSubscriptionPlanUseCase'));
      expect(premiumSource, contains('GetOfflineTrackEntitlementUseCase'));
      expect(premiumSource, contains('CheckUploadLimitUseCase'));
    });

    test('main does not duplicate premium dependency registration', () {
      expect(
        mainSource,
        isNot(contains('registerPremiumDependencies(getIt);')),
      );
      expect(
        mainSource,
        isNot(
          contains(
            "import 'package:soundcloud_clone/features/premium/premium_di.dart';",
          ),
        ),
      );
    });

    test('main still provides subscription cubit at root', () {
      expect(
        mainSource,
        contains('BlocProvider<SubscriptionCubit>('),
      );
      expect(
        mainSource,
        contains('getIt<SubscriptionCubit>()..loadSubscription()'),
      );
    });

    test('main still provides offline cubit at root', () {
      expect(
        mainSource,
        contains('BlocProvider<OfflineCubit>.value('),
      );
      expect(
        mainSource,
        contains('value: getIt<OfflineCubit>()'),
      );
    });
  });
}
