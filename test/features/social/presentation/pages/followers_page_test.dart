import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart'
    as auth;
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import 'package:soundcloud_clone/features/social/presentation/pages/followers_page.dart';

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

  final followers = [
    User(id: 'u1', username: 'omar', isFollowing: false, followersCount: 12),
    User(id: 'u2', username: 'mona', isFollowing: true, followersCount: 20),
  ];

  void stubGetFollowers(String userId, List<User> result) {
    when(
      () => mockSocialRepo.getFollowers(userId, 1, limit: 20),
    ).thenAnswer((_) async => result);
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    String? userId,
    String? handle,
  }) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<SocialRepo>.value(value: mockSocialRepo),
        ],
        child: BlocProvider<AuthCubit>.value(
          value: mockAuthCubit,
          child: MaterialApp(
            home: FollowersPage(userId: userId, handle: handle),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    mockSocialRepo = MockSocialRepo();
  });

  testWidgets('uses explicit userId when provided', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(
      mockAuthCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(authUser),
    );

    stubGetFollowers('explicit-id', followers);

    await pumpPage(tester, userId: 'explicit-id', handle: 'someone');

    verifyNever(() => mockSocialRepo.getUserIdByHandle(any()));
    verify(() => mockSocialRepo.getFollowers('explicit-id', 1, limit: 20))
        .called(1);

    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('omar'), findsOneWidget);
    expect(find.text('mona'), findsOneWidget);
    expect(find.text('12 followers'), findsOneWidget);
    expect(find.text('20 followers'), findsOneWidget);
    // omar: isFollowing=false → 'Follow'
    // mona: isFollowing=true  → 'Following'
    expect(find.text('Follow'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
  });

  testWidgets('uses authenticated user id when handle matches own profile',
      (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(
      mockAuthCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(authUser),
    );

    stubGetFollowers('auth-1', followers);

    await pumpPage(tester, handle: 'ali');

    verifyNever(() => mockSocialRepo.getUserIdByHandle(any()));
    verify(() => mockSocialRepo.getFollowers('auth-1', 1, limit: 20)).called(1);
  });

  testWidgets('resolves user id by handle when viewing another profile',
      (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(
      mockAuthCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(authUser),
    );

    when(() => mockSocialRepo.getUserIdByHandle('other-handle'))
        .thenAnswer((_) async => 'resolved-id');
    stubGetFollowers('resolved-id', followers);

    await pumpPage(tester, handle: 'other-handle');

    verify(() => mockSocialRepo.getUserIdByHandle('other-handle')).called(1);
    verify(() => mockSocialRepo.getFollowers('resolved-id', 1, limit: 20))
        .called(1);
  });

  testWidgets('shows empty state when handle is missing and no userId provided',
      (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(
      mockAuthCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(authUser),
    );

    await pumpPage(tester, handle: '');

    expect(find.text('User not found'), findsOneWidget);
    verifyNever(() => mockSocialRepo.getFollowers(any(), any()));
  });

  testWidgets('shows empty state when user id resolution fails',
      (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(
      mockAuthCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(authUser),
    );

    when(() => mockSocialRepo.getUserIdByHandle('broken'))
        .thenThrow(Exception('fail'));

    await pumpPage(tester, handle: 'broken');

    expect(find.text('User not found'), findsOneWidget);
    verifyNever(() => mockSocialRepo.getFollowers(any(), any()));
  });
}
