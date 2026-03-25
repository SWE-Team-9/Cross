import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/routes/profile_routes.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_state.dart';

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}
void main() {
  test('route constants remain correct', () {
    expect(ProfileRoutes.profile, '/profile/:handle');
    expect(ProfileRoutes.editProfile, '/profile/edit');
    expect(ProfileRoutes.followers, '/followers/:handle');
    expect(ProfileRoutes.following, '/following/:handle');
  });

  testWidgets('goToProfile pushes expected path', (tester) async {
    late String location;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ProfileRoutes.goToProfile(context, 'ali'),
                child: const Text('go'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/profile/:handle',
          builder: (context, state) {
            location = state.uri.toString();
            return const Scaffold(body: Text('profile'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(location, '/profile/ali');
  });

  testWidgets('goToFollowers pushes expected path', (tester) async {
    late String location;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ProfileRoutes.goToFollowers(context, 'ali'),
                child: const Text('go'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/followers/:handle',
          builder: (context, state) {
            location = state.uri.toString();
            return const Scaffold(body: Text('followers'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(location, '/followers/ali');
  });

  testWidgets('goToFollowing pushes expected path', (tester) async {
    late String location;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ProfileRoutes.goToFollowing(context, 'ali'),
                child: const Text('go'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/following/:handle',
          builder: (context, state) {
            location = state.uri.toString();
            return const Scaffold(body: Text('following'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(location, '/following/ali');
  });

testWidgets('goToEditProfile pushes edit path with current cubit as extra',
    (tester) async {
  final mockCubit = MockProfileCubit();
  Object? capturedExtra;

  when(() => mockCubit.state).thenReturn(ProfileInitial());
  whenListen(
    mockCubit,
    const Stream<ProfileState>.empty(),
    initialState: ProfileInitial(),
  );

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider<ProfileCubit>.value(
          value: mockCubit,
          child: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ProfileRoutes.goToEditProfile(context),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) {
          capturedExtra = state.extra;
          return const Scaffold(body: Text('edit'));
        },
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));

  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();

  expect(capturedExtra, same(mockCubit));
});
}