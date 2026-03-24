import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';

class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class TestProfileCubit extends ProfileCubit {
  TestProfileCubit({
    required super.getProfileUseCase,
    required super.updateProfileUseCase,
    required super.profileRepository,
  });
}

void main() {
  late TestProfileCubit cubit;

  setUp(() {
    cubit = TestProfileCubit(
      getProfileUseCase: MockGetProfileUseCase(),
      updateProfileUseCase: MockUpdateProfileUseCase(),
      profileRepository: MockProfileRepository(),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () =>
                      ProfileRoutes.goToProfile(context, 'ali-mahmoud'),
                  child: const Text('go-profile'),
                ),
                TextButton(
                  onPressed: () =>
                      ProfileRoutes.goToFollowers(context, 'ali-mahmoud'),
                  child: const Text('go-followers'),
                ),
                TextButton(
                  onPressed: () =>
                      ProfileRoutes.goToFollowing(context, 'ali-mahmoud'),
                  child: const Text('go-following'),
                ),
                TextButton(
                  onPressed: () => ProfileRoutes.goToEditProfile(context),
                  child: const Text('go-edit'),
                ),
              ],
            ),
          ),
        ),

        // IMPORTANT: put /profile/edit before /profile/:handle
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) {
            final extra = state.extra;
            return Text('edit:${extra is ProfileCubit}');
          },
        ),
        GoRoute(
          path: '/profile/:handle',
          builder: (context, state) => Text(
            'profile:${state.pathParameters['handle']}',
          ),
        ),
        GoRoute(
          path: '/followers/:handle',
          builder: (context, state) => Text(
            'followers:${state.pathParameters['handle']}',
          ),
        ),
        GoRoute(
          path: '/following/:handle',
          builder: (context, state) => Text(
            'following:${state.pathParameters['handle']}',
          ),
        ),
      ],
    );

    return BlocProvider<ProfileCubit>.value(
      value: cubit,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ProfileRoutes', () {
    test('exposes expected route constants', () {
      expect(ProfileRoutes.profile, '/profile/:handle');
      expect(ProfileRoutes.editProfile, '/profile/edit');
      expect(ProfileRoutes.followers, '/followers/:handle');
      expect(ProfileRoutes.following, '/following/:handle');
    });

    testWidgets('goToProfile pushes profile route with handle', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('go-profile'));
      await tester.pumpAndSettle();

      expect(find.text('profile:ali-mahmoud'), findsOneWidget);
    });

    testWidgets('goToFollowers pushes followers route with handle',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('go-followers'));
      await tester.pumpAndSettle();

      expect(find.text('followers:ali-mahmoud'), findsOneWidget);
    });

    testWidgets('goToFollowing pushes following route with handle',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('go-following'));
      await tester.pumpAndSettle();

      expect(find.text('following:ali-mahmoud'), findsOneWidget);
    });

    testWidgets('goToEditProfile pushes edit route with cubit as extra',
        (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('go-edit'));
      await tester.pumpAndSettle();

      expect(find.text('edit:true'), findsOneWidget);
    });
  });
}
