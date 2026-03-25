import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/widgets/paginated_user_list.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart'
    as auth_user;
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import 'package:soundcloud_clone/features/social/presentation/pages/following_page.dart';

class MockSocialRepo extends Mock implements SocialRepo {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockSocialRepo repo;
  late MockAuthCubit authCubit;

  const currentUser = auth_user.User(
    id: 'user-1',
    email: 'ali@example.com',
    handle: 'ali',
    displayName: 'Ali',
    username: 'ali',
    isVerified: true,
  );

  Widget buildTestWidget() {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SocialRepo>.value(value: repo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
        ],
        child: const MaterialApp(
          home: FollowingPage(handle: 'ali'),
        ),
      ),
    );
  }

  setUp(() {
    repo = MockSocialRepo();
    authCubit = MockAuthCubit();

    when(() => authCubit.state).thenReturn(AuthAuthenticated(currentUser));

    when(() => repo.getFollowing('user-1', any()))
        .thenAnswer((_) async => const <User>[]);

    when(() => repo.getUserIdByHandle(any())).thenAnswer((_) async => 'user-1');
  });

  group('FollowingPage', () {
    testWidgets('renders app bar title and empty state', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Not following anyone yet'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);
    });

    testWidgets('uses black scaffold background', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('contains PaginatedUserList<User>', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PaginatedUserList<User>), findsOneWidget);
    });

    testWidgets('stores provided handle', (tester) async {
      const page = FollowingPage(handle: 'ali');
      expect(page.handle, 'ali');
    });

    testWidgets('uses authenticated user id when handle matches current user',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      verify(() => repo.getFollowing('user-1', 1)).called(1);
      verifyNever(() => repo.getUserIdByHandle('ali'));
    });
  });
}
