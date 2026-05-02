import 'package:bloc/bloc.dart';
import '../../../domain/enums/user_action_type.dart';
import '../../../data/repositories/social_repo.dart';
import '../../../domain/events/social_events.dart';

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
          SocialEvents.emitFollowChanged();
          break;

        case UserActionType.unfollow:
          await repo.unfollowUser(userId);
          SocialEvents.emitFollowChanged();
          break;

        case UserActionType.block:
          await repo.blockUser(userId);
          break;

        case UserActionType.unblock:
          await repo.unblockUser(userId);
          break;
      }

      emit(UserActionSuccess(
        userId: userId,
        action: action,
      ));
    } catch (e) {
      emit(UserActionError(e.toString()));
    }
  }
}
