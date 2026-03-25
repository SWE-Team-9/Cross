import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/domain/enums/user_action_type.dart';
import 'package:soundcloud_clone/features/social/presentation/bloc/user_action_bloc/user_action_cubit.dart';

class MockSocialRepo extends Mock implements SocialRepo {}

void main() {
  late MockSocialRepo mockRepo;
  late UserActionCubit cubit;

  setUp(() {
    mockRepo = MockSocialRepo();
    cubit = UserActionCubit(mockRepo);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('initial state is UserActionInitial', () {
    expect(cubit.state, isA<UserActionInitial>());
  });

  blocTest<UserActionCubit, UserActionState>(
    'performAction follow emits loading then success',
    build: () {
      when(() => mockRepo.followUser('u1')).thenAnswer((_) async => true);
      return cubit;
    },
    act: (cubit) => cubit.performAction(
      userId: 'u1',
      action: UserActionType.follow,
    ),
    expect: () => [
      isA<UserActionLoading>(),
      isA<UserActionSuccess>(),
    ],
  );

  blocTest<UserActionCubit, UserActionState>(
    'performAction unfollow emits loading then success',
    build: () {
      when(() => mockRepo.unfollowUser('u1')).thenAnswer((_) async => true);
      return cubit;
    },
    act: (cubit) => cubit.performAction(
      userId: 'u1',
      action: UserActionType.unfollow,
    ),
    expect: () => [
      isA<UserActionLoading>(),
      isA<UserActionSuccess>(),
    ],
  );

  blocTest<UserActionCubit, UserActionState>(
    'performAction block emits loading then success',
    build: () {
      when(() => mockRepo.blockUser('u1')).thenAnswer((_) async => true);
      return cubit;
    },
    act: (cubit) => cubit.performAction(
      userId: 'u1',
      action: UserActionType.block,
    ),
    expect: () => [
      isA<UserActionLoading>(),
      isA<UserActionSuccess>(),
    ],
  );

  blocTest<UserActionCubit, UserActionState>(
    'performAction unblock emits loading then success',
    build: () {
      when(() => mockRepo.unblockUser('u1')).thenAnswer((_) async => true);
      return cubit;
    },
    act: (cubit) => cubit.performAction(
      userId: 'u1',
      action: UserActionType.unblock,
    ),
    expect: () => [
      isA<UserActionLoading>(),
      isA<UserActionSuccess>(),
    ],
  );

  blocTest<UserActionCubit, UserActionState>(
    'performAction emits error on exception',
    build: () {
      when(() => mockRepo.followUser('u1')).thenThrow(Exception('boom'));
      return cubit;
    },
    act: (cubit) => cubit.performAction(
      userId: 'u1',
      action: UserActionType.follow,
    ),
    expect: () => [
      isA<UserActionLoading>(),
      isA<UserActionError>(),
    ],
  );
}