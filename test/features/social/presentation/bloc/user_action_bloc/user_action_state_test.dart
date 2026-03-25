import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/social/domain/enums/user_action_type.dart';
import 'package:soundcloud_clone/features/social/presentation/bloc/user_action_bloc/user_action_cubit.dart';

void main() {
  test('UserActionInitial can be created', () {
    expect(UserActionInitial(), isA<UserActionInitial>());
  });

  test('UserActionLoading can be created', () {
    expect(UserActionLoading(), isA<UserActionLoading>());
  });

  test('UserActionSuccess stores values', () {
    final state = UserActionSuccess(
      userId: 'u1',
      action: UserActionType.follow,
    );

    expect(state.userId, 'u1');
    expect(state.action, UserActionType.follow);
  });

  test('UserActionError stores message', () {
    final state = UserActionError('failed');

    expect(state.message, 'failed');
  });
}
