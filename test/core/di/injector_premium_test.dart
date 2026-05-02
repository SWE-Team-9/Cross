import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('injector premium registration', () {
    late String injectorSource;

    setUpAll(() {
      injectorSource = File('lib/core/di/injector.dart').readAsStringSync();
    });

    test('imports premium dependency module', () {
      expect(
        injectorSource,
        contains(
          "import 'package:soundcloud_clone/features/premium/premium_di.dart';",
        ),
      );
    });

    test('registers premium dependencies after DioClient registration', () {
      final dioClientRegistrationIndex = injectorSource.indexOf(
        'getIt.registerLazySingleton<DioClient>',
      );
      final premiumRegistrationIndex = injectorSource.indexOf(
        'registerPremiumDependencies(getIt);',
      );

      expect(dioClientRegistrationIndex, isNonNegative);
      expect(premiumRegistrationIndex, isNonNegative);
      expect(premiumRegistrationIndex, greaterThan(dioClientRegistrationIndex));
    });

    test('registers premium dependencies before upload picker cubit', () {
      final premiumRegistrationIndex = injectorSource.indexOf(
        'registerPremiumDependencies(getIt);',
      );
      final uploadPickerCubitRegistrationIndex = injectorSource.indexOf(
        'getIt.registerFactory<UploadPickerCubit>',
      );

      expect(premiumRegistrationIndex, isNonNegative);
      expect(uploadPickerCubitRegistrationIndex, isNonNegative);
      expect(
        uploadPickerCubitRegistrationIndex,
        greaterThan(premiumRegistrationIndex),
      );
    });

    test('keeps upload picker wired to subscription repository and upload limit use case', () {
      expect(
        injectorSource,
        contains('getIt<SubscriptionRepository>()'),
      );
      expect(
        injectorSource,
        contains('getIt<CheckUploadLimitUseCase>()'),
      );
    });

    test('keeps premium-related imports required by existing injector registrations', () {
      expect(
        injectorSource,
        contains(
          "import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';",
        ),
      );
      expect(
        injectorSource,
        contains(
          "import 'package:soundcloud_clone/features/upload/domain/usecases/check_upload_limit_usecase.dart';",
        ),
      );
      expect(
        injectorSource,
        contains(
          "import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';",
        ),
      );
      expect(
        injectorSource,
        contains(
          "import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';",
        ),
      );
    });

    test('does not register premium dependencies before core network setup', () {
      final secureStorageRegistrationIndex = injectorSource.indexOf(
        'getIt.registerLazySingleton<SecureStorage>',
      );
      final dioClientRegistrationIndex = injectorSource.indexOf(
        'getIt.registerLazySingleton<DioClient>',
      );
      final premiumRegistrationIndex = injectorSource.indexOf(
        'registerPremiumDependencies(getIt);',
      );

      expect(secureStorageRegistrationIndex, isNonNegative);
      expect(dioClientRegistrationIndex, isNonNegative);
      expect(premiumRegistrationIndex, isNonNegative);

      expect(dioClientRegistrationIndex, greaterThan(secureStorageRegistrationIndex));
      expect(premiumRegistrationIndex, greaterThan(dioClientRegistrationIndex));
    });
  });
}