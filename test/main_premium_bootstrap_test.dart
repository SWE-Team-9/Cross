import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('main premium bootstrap', () {
    late String source;

    setUpAll(() {
      source = File('lib/main.dart').readAsStringSync();
    });

    test('does not import premium dependency module directly', () {
      expect(
        source,
        isNot(
          contains(
            "import 'package:soundcloud_clone/features/premium/premium_di.dart';",
          ),
        ),
      );
    });

    test('does not register premium dependencies twice', () {
      expect(
        source,
        isNot(contains('registerPremiumDependencies(getIt);')),
      );
    });

    test('relies on setupDependencies for app dependency registration', () {
      expect(
        source,
        contains('await setupDependencies();'),
      );

      final setupIndex = source.indexOf('await setupDependencies();');
      final deepLinkIndex =
          source.indexOf("await getIt<DeepLinkService>().init();");

      expect(setupIndex, isNonNegative);
      expect(deepLinkIndex, isNonNegative);
      expect(setupIndex, lessThan(deepLinkIndex));
    });

    test('initializes deep link service after dependencies are ready', () {
      expect(
        source,
        contains("import 'core/deep_links/deep_link_service.dart';"),
      );
      expect(
        source,
        contains("await getIt<DeepLinkService>().init();"),
      );
    });

    test('provides subscription cubit at app root and loads subscription', () {
      expect(
        source,
        contains(
            "import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';"),
      );
      expect(
        source,
        contains('BlocProvider<SubscriptionCubit>('),
      );
      expect(
        source,
        contains(
            'create: (_) => getIt<SubscriptionCubit>()..loadSubscription(),'),
      );
    });

    test('provides offline cubit at app root', () {
      expect(
        source,
        contains(
            "import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';"),
      );
      expect(
        source,
        contains('BlocProvider<OfflineCubit>.value('),
      );
      expect(
        source,
        contains('value: getIt<OfflineCubit>(),'),
      );
    });

    test('keeps app wrapped with MultiBlocProvider', () {
      expect(
        source,
        contains('runApp('),
      );
      expect(
        source,
        contains('MultiBlocProvider('),
      );
      expect(
        source,
        contains('child: App(),'),
      );
    });

    test('keeps audio service initialization before dependency setup', () {
      final audioServiceIndex =
          source.indexOf('audioHandler = await AudioService.init(');
      final setupIndex = source.indexOf('await setupDependencies();');

      expect(audioServiceIndex, isNonNegative);
      expect(setupIndex, isNonNegative);
      expect(audioServiceIndex, lessThan(setupIndex));
    });
  });
}
