import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import 'package:soundcloud_clone/features/social/presentation/bloc/follow_bloc/cubit/blocked_users_cubit.dart';
import 'package:soundcloud_clone/features/social/presentation/pages/blocked_users_page.dart';

class MockSocialRepo extends Mock implements SocialRepo {}

class MockDio extends Mock implements Dio {}

User makeUser(String id, String username) => User(id: id, username: username);

void main() {
  late MockSocialRepo repo;

  setUp(() {
    repo = MockSocialRepo();
    when(() => repo.dio).thenReturn(MockDio());
  });

  group('BlockedUsersCubit', () {
    test('loadInitial fetches first page', () async {
      final cubit = BlockedUsersCubit(repo);
      when(() => repo.getBlockedUsers(1, limit: 20))
          .thenAnswer((_) async => [makeUser('1', 'ali')]);

      await cubit.loadInitial();

      expect(cubit.state.users.single.username, 'ali');
      expect(cubit.state.currentPage, 1);
      expect(cubit.state.loading, isFalse);
      await cubit.close();
    });

    test('loadMore appends next page', () async {
      final cubit = BlockedUsersCubit(repo);
      when(() => repo.getBlockedUsers(1, limit: 20)).thenAnswer(
        (_) async =>
            List.generate(20, (index) => makeUser('$index', 'u$index')),
      );
      when(() => repo.getBlockedUsers(2, limit: 20))
          .thenAnswer((_) async => [makeUser('21', 'extra')]);

      await cubit.loadInitial();
      await cubit.loadMore();

      expect(cubit.state.users.length, 21);
      expect(cubit.state.users.last.username, 'extra');
      await cubit.close();
    });

    test('unblockUser restores snapshot when request fails', () async {
      final cubit = BlockedUsersCubit(repo);
      when(() => repo.unblockUser('1')).thenAnswer((_) async => false);

      cubit.emit(
        BlockedUsersState(users: [
          makeUser('1', 'ali'),
          makeUser('2', 'salma'),
        ]),
      );

      await cubit.unblockUser(makeUser('1', 'ali'));

      expect(cubit.state.users.length, 2);
      await cubit.close();
    });
  });

  group('BlockedUsersPage', () {
    Widget buildPage() {
      return RepositoryProvider<SocialRepo>.value(
        value: repo,
        child: const MaterialApp(home: BlockedUsersPage()),
      );
    }

    testWidgets('shows empty state', (tester) async {
      when(() => repo.getBlockedUsers(1, limit: 20))
          .thenAnswer((_) async => const []);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No blocked accounts'), findsOneWidget);
    });

    testWidgets('shows retry state on error', (tester) async {
      when(() => repo.getBlockedUsers(1, limit: 20))
          .thenThrow(Exception('network'));

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      verify(() => repo.getBlockedUsers(1, limit: 20)).called(greaterThan(1));
    });

    testWidgets('renders users and unblocks after confirmation',
        (tester) async {
      when(() => repo.getBlockedUsers(1, limit: 20))
          .thenAnswer((_) async => [makeUser('1', 'ali')]);
      when(() => repo.unblockUser('1')).thenAnswer((_) async => true);

      await tester.pumpWidget(buildPage());
      await tester.pumpAndSettle();

      expect(find.text('ali'), findsOneWidget);

      await tester.tap(find.text('Unblock'));
      await tester.pumpAndSettle();
      expect(find.text('Unblock ali?'), findsOneWidget);

      await tester.tap(find.text('Unblock').last);
      await tester.pumpAndSettle();

      verify(() => repo.unblockUser('1')).called(1);
      expect(find.text('ali'), findsNothing);
    });
  });
}
