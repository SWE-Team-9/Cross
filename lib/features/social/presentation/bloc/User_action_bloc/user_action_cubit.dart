import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/enums/user_action_type.dart';
import '../../../data/repositories/social_repo.dart';

part 'user_action_state.dart';

class UserActionCubit extends Cubit<UserActionState> {
  final SocialRepo repo;

  UserActionCubit(this.repo) : super(UserActionInitial());

  Future<void> performAction({
    required String userId,
    required UserActionType action,
  }) async {
    emit(UserActionLoading());

    try {
      switch (action) {
        case UserActionType.follow:
          await repo.followUser(userId);
          break;

        case UserActionType.unfollow:
          await repo.unfollowUser(userId);
          break;

        case UserActionType.block:
          await repo.blockUser(userId);
          break;

        case UserActionType.unblock:
          await repo.unblockUser(userId);
          break;
      }

      emit(UserActionSuccess(action));
    } catch (e) {
      emit(UserActionError(e.toString()));
    }
  }
}
