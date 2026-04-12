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
    whenListen(
      mockAuthCubit,
      const Stream<AuthState>.empty(),
      initialState: AuthAuthenticated(authUser),
    );

    stubGetFollowing('auth-1', following);

    await pumpPage(tester, handle: 'ali');

    verifyNever(() => mockSocialRepo.getUserIdByHandle(any()));
    verify(() => mockSocialRepo.getFollowing('auth-1', 1, limit: 20)).called(1);

    // الـ appbar title = 'Following' (bold white)
    // زراير الـ users = 'Following' (grey)
    // نتحقق إن الـ usernames موجودين
    expect(find.text('omar'), findsOneWidget);
    expect(find.text('mona'), findsOneWidget);
    expect(find.text('12 followers'), findsOneWidget);
    expect(find.text('20 followers'), findsOneWidget);
    // 'Following' بيظهر 3 مرات: appbar + زرار omar + زرار mona
    expect(find.text('Following'), findsNWidgets(3));
    // الـ more_horiz button لكل يوزر
    expect(find.byIcon(Icons.more_horiz), findsNWidgets(2));
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
    stubGetFollowing('resolved-id', following);

    await pumpPage(tester, handle: 'other-handle');

    verify(() => mockSocialRepo.getUserIdByHandle('other-handle')).called(1);
    verify(() => mockSocialRepo.getFollowing('resolved-id', 1, limit: 20))
        .called(1);
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
    verifyNever(() => mockSocialRepo.getFollowing(any(), any()));
  });
}
