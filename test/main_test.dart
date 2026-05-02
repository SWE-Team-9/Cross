import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('main premium bootstrap', () {
    late String mainSource;

    setUpAll(() {
      mainSource = File('lib/main.dart').readAsStringSync();
    });

    test('registers premium dependencies after app dependencies are ready', () {
      final setupDependenciesIndex = mainSource.indexOf(
        'await setupDependencies();',
      );
      final registerPremiumDependenciesIndex = mainSource.indexOf(
        'registerPremiumDependencies(getIt);',
      );

      expect(setupDependenciesIndex, isNonNegative);
      expect(registerPremiumDependenciesIndex, isNonNegative);
      expect(registerPremiumDependenciesIndex, greaterThan(setupDependenciesIndex));
    });

    test('initializes deep links after premium dependencies are registered', () {
      final registerPremiumDependenciesIndex = mainSource.indexOf(
        'registerPremiumDependencies(getIt);',
      );
      final deepLinkInitIndex = mainSource.indexOf(
        'await getIt<DeepLinkService>().init();',
      );

      expect(registerPremiumDependenciesIndex, isNonNegative);
      expect(deepLinkInitIndex, isNonNegative);
      expect(deepLinkInitIndex, greaterThan(registerPremiumDependenciesIndex));
    });

    test('provides subscription cubit at app root and loads subscription', () {
      expect(mainSource, contains('MultiBlocProvider'));
      expect(mainSource, contains('BlocProvider<SubscriptionCubit>'));
      expect(
        mainSource,
        contains('create: (_) => getIt<SubscriptionCubit>()..loadSubscription()'),
      );
    });

    test('provides offline cubit at app root', () {
      expect(mainSource, contains('BlocProvider<OfflineCubit>.value'));
      expect(mainSource, contains('value: getIt<OfflineCubit>()'));
    });

    test('imports premium dependency module and cubits', () {
      expect(
        mainSource,
        contains(
          "import 'package:soundcloud_clone/features/premium/premium_di.dart';",
        ),
      );
      expect(
        mainSource,
        contains(
          "import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';",
        ),
      );
      expect(
        mainSource,
        contains(
          "import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';",
        ),
      );
    });

    test('keeps audio service initialization before dependency setup', () {
      final audioServiceInitIndex = mainSource.indexOf(
        'audioHandler = await AudioService.init(',
      );
      final setupDependenciesIndex = mainSource.indexOf(
        'await setupDependencies();',
      );

      expect(audioServiceInitIndex, isNonNegative);
      expect(setupDependenciesIndex, isNonNegative);
      expect(setupDependenciesIndex, greaterThan(audioServiceInitIndex));
    });

    test('runs App inside root MultiBlocProvider', () {
      expect(mainSource, contains('runApp('));
      expect(mainSource, contains('child: App(),'));
    });
  });
}