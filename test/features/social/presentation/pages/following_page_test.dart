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
    User(id: 'u1', username: 'omar', isFollowing: true, followersCount: 12),
    User(id: 'u2', username: 'mona', isFollowing: true, followersCount: 20),
  ];

  void stubGetFollowing(String userId, List<User> result) {
    when(
      () => mockSocialRepo.getFollowing(userId, 1, limit: 20),
    ).thenAnswer((_) async => result);
  }

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
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    mockSocialRepo = MockSocialRepo();
  });

  testWidgets('uses authenticated user id when viewing own following',
      (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(mockAuthCubit, const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(authUser));

    stubGetFollowing('auth-1', following);

    await pumpPage(tester, handle: 'ali');

    verifyNever(() => mockSocialRepo.getUserIdByHandle(any()));
    verify(() => mockSocialRepo.getFollowing('auth-1', 1, limit: 20)).called(1);

    expect(find.text('omar'), findsOneWidget);
    expect(find.text('mona'), findsOneWidget);
    expect(find.text('12 followers'), findsOneWidget);
    expect(find.text('20 followers'), findsOneWidget);
    expect(find.text('Following'), findsNWidgets(3));
    expect(find.byIcon(Icons.more_horiz), findsNWidgets(2));
  });

  testWidgets('resolves user id by handle for another profile', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(mockAuthCubit, const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(authUser));

    when(() => mockSocialRepo.getUserIdByHandle('other-handle'))
        .thenAnswer((_) async => 'resolved-id');
    stubGetFollowing('resolved-id', following);

    await pumpPage(tester, handle: 'other-handle');

    verify(() => mockSocialRepo.getUserIdByHandle('other-handle')).called(1);
    verify(() => mockSocialRepo.getFollowing('resolved-id', 1, limit: 20))
        .called(1);
  });

  testWidgets('shows User not found when user id resolution fails',
      (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(mockAuthCubit, const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(authUser));

    when(() => mockSocialRepo.getUserIdByHandle('broken'))
        .thenThrow(Exception('fail'));

    await pumpPage(tester, handle: 'broken');

    expect(find.text('User not found'), findsOneWidget);
    verifyNever(() => mockSocialRepo.getFollowing(any(), any()));
  });

  testWidgets('shows empty state when API returns empty list', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(mockAuthCubit, const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(authUser));

    stubGetFollowing('auth-1', []);

    await pumpPage(tester, handle: 'ali');

    expect(find.text('Not following anyone yet'), findsOneWidget);
    expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);
  });

  testWidgets('shows error state when API throws', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(mockAuthCubit, const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(authUser));

    when(() => mockSocialRepo.getFollowing('auth-1', 1, limit: 20))
        .thenThrow(Exception('network error'));

    await pumpPage(tester, handle: 'ali');

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping Following button triggers unfollowUser', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(mockAuthCubit, const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(authUser));

    stubGetFollowing('auth-1', following);

    when(() => mockSocialRepo.unfollowUser('u1')).thenAnswer(
      (_) async => (isFollowing: false, followersCount: null),
    );

    await pumpPage(tester, handle: 'ali');

    // اضغط على أول زرار Following
    await tester.tap(find.text('Following').first);
    await tester.pumpAndSettle();

    verify(() => mockSocialRepo.unfollowUser('u1')).called(1);
  });

  testWidgets('tapping more_horiz shows block confirmation dialog',
      (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(mockAuthCubit, const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(authUser));

    stubGetFollowing('auth-1', following);

    await pumpPage(tester, handle: 'ali');

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();

    expect(find.text('Block omar?'), findsOneWidget);
    expect(find.text('Block'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('tapping Cancel in block dialog dismisses it', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(mockAuthCubit, const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(authUser));

    stubGetFollowing('auth-1', following);

    await pumpPage(tester, handle: 'ali');

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Block omar?'), findsNothing);
    verifyNever(() => mockSocialRepo.blockUser(any()));
  });

  testWidgets('confirming block calls blockUser', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(authUser));
    whenListen(mockAuthCubit, const Stream<AuthState>.empty(),
        initialState: AuthAuthenticated(authUser));

    stubGetFollowing('auth-1', following);
    when(() => mockSocialRepo.blockUser('u1')).thenAnswer((_) async => true);

    await pumpPage(tester, handle: 'ali');

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();

    verify(() => mockSocialRepo.blockUser('u1')).called(1);
  });
}
