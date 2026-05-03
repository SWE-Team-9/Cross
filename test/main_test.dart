import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('main premium bootstrap', () {
    late String mainSource;

    setUpAll(() {
      mainSource =
          File('lib/main.dart').readAsStringSync().replaceAll('\r\n', '\n');
    });

    test('relies on setupDependencies for premium registration', () {
      final setupDependenciesIndex = mainSource.indexOf(
        'await setupDependencies();',
      );

      expect(setupDependenciesIndex, isNonNegative);
      expect(
          mainSource, isNot(contains('registerPremiumDependencies(getIt);')));
    });

    test('initializes deep links after app dependencies are registered', () {
      final setupDependenciesIndex = mainSource.indexOf(
        'await setupDependencies();',
      );
      final deepLinkInitIndex = mainSource.indexOf(
        'await getIt<DeepLinkService>().init();',
      );

      expect(setupDependenciesIndex, isNonNegative);
      expect(deepLinkInitIndex, isNonNegative);
      expect(deepLinkInitIndex, greaterThan(setupDependenciesIndex));
    });

    test('provides subscription cubit at app root and loads subscription', () {
      expect(mainSource, contains('MultiBlocProvider'));
      expect(mainSource, contains('BlocProvider<SubscriptionCubit>'));
      expect(
        mainSource,
        contains(
            'create: (_) => getIt<SubscriptionCubit>()..loadSubscription()'),
      );
    });

    test('provides offline cubit at app root', () {
      expect(mainSource, contains('BlocProvider<OfflineCubit>.value'));
      expect(mainSource, contains('value: getIt<OfflineCubit>()'));
    });

    test('imports root cubits', () {
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
