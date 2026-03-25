import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart' as auth;
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import 'package:soundcloud_clone/features/social/presentation/pages/following_page.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockSocialRepo extends Mock implements SocialRepo {}

void main() {
  late MockAuthCubit mockAuthCubit;
  late MockSocialRepo mockSocialRepo;

  const authUser = auth.User(
    id: 'auth-1',
    email: 'ali@test.com',
    handle: 'ali',
    displayName: 'Ali',
  );

  final following = [
    User(
      id: 'u1',
      username: 'omar',
      isFollowing: true,
      followersCount: 12,
    ),
    User(
      id: 'u2',
      username: 'mona',
      isFollowing: true,
      followersCount: 20,
    ),
  ];

  Future<void> pumpPage(
    WidgetTester tester, {
    required String handle,
  }) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SocialRepo>.value(value: mockSocialRepo),
        ],
        child: BlocProvider<AuthCubit>.value(
          value: mockAuthCubit,
          child: MaterialApp(
            home: FollowingPage(handle: handle),
          ),
        ),
      ),
    );
  }

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    mockSocialRepo = MockSocialRepo();
  });

  testWidgets('uses authenticated user id when viewing own following',
      (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(
      mockAuthCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(authUser),
    );

    when(() => mockSocialRepo.getFollowing('auth-1', 1))
        .thenAnswer((_) async => following);

    await pumpPage(
      tester,
      handle: 'ali',
    );
    await tester.pumpAndSettle();

    verifyNever(() => mockSocialRepo.getUserIdByHandle(any()));
    verify(() => mockSocialRepo.getFollowing('auth-1', 1)).called(1);

    expect(find.text('Following'), findsOneWidget);
    expect(find.text('omar'), findsOneWidget);
    expect(find.text('mona'), findsOneWidget);
    expect(find.text('12 followers'), findsOneWidget);
    expect(find.text('20 followers'), findsOneWidget);
    expect(find.text('Unfollow'), findsNWidgets(2));
    expect(find.text('Block'), findsNWidgets(2));
  });

  testWidgets('resolves user id by handle for another profile', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(
      mockAuthCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(authUser),
    );

    when(() => mockSocialRepo.getUserIdByHandle('other-handle'))
        .thenAnswer((_) async => 'resolved-id');
    when(() => mockSocialRepo.getFollowing('resolved-id', 1))
        .thenAnswer((_) async => following);

    await pumpPage(
      tester,
      handle: 'other-handle',
    );
    await tester.pumpAndSettle();

    verify(() => mockSocialRepo.getUserIdByHandle('other-handle')).called(1);
    verify(() => mockSocialRepo.getFollowing('resolved-id', 1)).called(1);
  });

  testWidgets('shows empty state when user id resolution fails', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(
      mockAuthCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(authUser),
    );

    when(() => mockSocialRepo.getUserIdByHandle('broken'))
        .thenThrow(Exception('fail'));

    await pumpPage(
      tester,
      handle: 'broken',
    );
    await tester.pumpAndSettle();

    expect(find.text('Not following anyone yet'), findsOneWidget);
    verifyNever(() => mockSocialRepo.getFollowing(any(), any()));
  });
}