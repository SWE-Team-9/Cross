import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_state.dart';
import 'package:soundcloud_clone/features/premium/presentation/widgets/premium_aware_ad_banner.dart';

class MockSubscriptionCubit extends MockCubit<SubscriptionState>
    implements SubscriptionCubit {}

void main() {
  const freeState = SubscriptionState(
    status: SubscriptionStatus.loaded,
    subscription: Subscription(
      planCode: 'FREE',
      subscriptionType: 'FREE',
      subscriptionStatus: 'ACTIVE',
      planName: 'Free',
      isPremium: false,
      adsEnabled: true,
      canDownload: false,
      uploadLimit: 3,
      uploadedTracks: 1,
      remainingUploads: 2,
    ),
  );

  const premiumState = SubscriptionState(
    status: SubscriptionStatus.loaded,
    subscription: Subscription(
      planCode: 'PRO',
      subscriptionType: 'PRO',
      subscriptionStatus: 'ACTIVE',
      planName: 'Pro',
      isPremium: true,
      adsEnabled: false,
      canDownload: true,
      uploadLimit: 100,
      uploadedTracks: 10,
      remainingUploads: 90,
    ),
  );

  late MockSubscriptionCubit subscriptionCubit;

  setUp(() async {
    await GetIt.I.reset();

    subscriptionCubit = MockSubscriptionCubit();

    when(() => subscriptionCubit.state).thenReturn(freeState);
    when(() => subscriptionCubit.stream).thenAnswer(
      (_) => const Stream<SubscriptionState>.empty(),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('PremiumAwareAdBanner', () {
    testWidgets('renders ad banner for free users with ads enabled',
        (tester) async {
      when(() => subscriptionCubit.state).thenReturn(freeState);

      await _pumpBanner(
        tester,
        subscriptionCubit: subscriptionCubit,
      );

      expect(find.text('Sponsored'), findsOneWidget);
      expect(find.text('Create without limits'), findsOneWidget);
      expect(
        find.text(
          'Upgrade to remove ads, unlock offline downloads, and get more uploads.',
        ),
        findsOneWidget,
      );
      expect(find.text('Go Premium'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
    });

    testWidgets('hides banner for premium users with ads disabled',
        (tester) async {
      when(() => subscriptionCubit.state).thenReturn(premiumState);

      await _pumpBanner(
        tester,
        subscriptionCubit: subscriptionCubit,
      );

      expect(find.text('Sponsored'), findsNothing);
      expect(find.text('Create without limits'), findsNothing);
      expect(find.text('Go Premium'), findsNothing);
    });

    testWidgets('hides banner while subscription state is initial',
        (tester) async {
      when(() => subscriptionCubit.state).thenReturn(
        const SubscriptionState(status: SubscriptionStatus.initial),
      );

      await _pumpBanner(
        tester,
        subscriptionCubit: subscriptionCubit,
      );

      expect(find.text('Sponsored'), findsNothing);
      expect(find.text('Create without limits'), findsNothing);
    });

    testWidgets('hides banner while subscription state is loading',
        (tester) async {
      when(() => subscriptionCubit.state).thenReturn(
        const SubscriptionState(status: SubscriptionStatus.loading),
      );

      await _pumpBanner(
        tester,
        subscriptionCubit: subscriptionCubit,
      );

      expect(find.text('Sponsored'), findsNothing);
      expect(find.text('Create without limits'), findsNothing);
    });

    testWidgets('renders banner when subscription cubit is unavailable',
        (tester) async {
      await _pumpBanner(
        tester,
        subscriptionCubit: null,
      );

      expect(find.text('Sponsored'), findsOneWidget);
      expect(find.text('Create without limits'), findsOneWidget);
      expect(find.text('Go Premium'), findsOneWidget);
    });

    testWidgets('reads subscription cubit from GetIt fallback', (tester) async {
      when(() => subscriptionCubit.state).thenReturn(freeState);
      GetIt.I.registerSingleton<SubscriptionCubit>(subscriptionCubit);

      await _pumpBanner(
        tester,
        subscriptionCubit: null,
      );

      expect(find.text('Sponsored'), findsOneWidget);
      expect(find.text('Create without limits'), findsOneWidget);
      expect(find.text('Go Premium'), findsOneWidget);
    });

    testWidgets('hides banner from GetIt fallback for premium user',
        (tester) async {
      when(() => subscriptionCubit.state).thenReturn(premiumState);
      GetIt.I.registerSingleton<SubscriptionCubit>(subscriptionCubit);

      await _pumpBanner(
        tester,
        subscriptionCubit: null,
      );

      expect(find.text('Sponsored'), findsNothing);
      expect(find.text('Create without limits'), findsNothing);
    });

    testWidgets('renders custom title subtitle and action label',
        (tester) async {
      when(() => subscriptionCubit.state).thenReturn(freeState);

      await _pumpBanner(
        tester,
        subscriptionCubit: subscriptionCubit,
        banner: const PremiumAwareAdBanner(
          title: 'No interruptions',
          subtitle: 'Go Pro to remove sponsored cards.',
          actionLabel: 'Upgrade now',
        ),
      );

      expect(find.text('Sponsored'), findsOneWidget);
      expect(find.text('No interruptions'), findsOneWidget);
      expect(find.text('Go Pro to remove sponsored cards.'), findsOneWidget);
      expect(find.text('Upgrade now'), findsOneWidget);
      expect(find.text('Create without limits'), findsNothing);
    });

    testWidgets('action button navigates to upgrade route', (tester) async {
      when(() => subscriptionCubit.state).thenReturn(freeState);

      await _pumpBanner(
        tester,
        subscriptionCubit: subscriptionCubit,
      );

      await tester.tap(find.text('Go Premium'));
      await tester.pumpAndSettle();

      expect(find.text('Upgrade Route'), findsOneWidget);
    });
  });
}

Future<void> _pumpBanner(
  WidgetTester tester, {
  required MockSubscriptionCubit? subscriptionCubit,
  PremiumAwareAdBanner banner = const PremiumAwareAdBanner(),
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final scaffold = Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: banner),
          );

          if (subscriptionCubit == null) {
            return scaffold;
          }

          return BlocProvider<SubscriptionCubit>.value(
            value: subscriptionCubit,
            child: scaffold,
          );
        },
      ),
      GoRoute(
        path: '/upgrade',
        builder: (context, state) {
          return const Scaffold(
            body: Center(
              child: Text('Upgrade Route'),
            ),
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
    ),
  );

  await tester.pumpAndSettle();
}
