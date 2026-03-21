part of 'user_action_cubit.dart';

abstract class UserActionState {}

class UserActionInitial extends UserActionState {}

class UserActionLoading extends UserActionState {}

class UserActionSuccess extends UserActionState {
  final UserActionType action;
  UserActionSuccess(this.action);
}

class UserActionError extends UserActionState {
  final String message;
  UserActionError(this.message);
}
