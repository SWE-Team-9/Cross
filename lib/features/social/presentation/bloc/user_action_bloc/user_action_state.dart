part of 'user_action_cubit.dart';

abstract class UserActionState {}

class UserActionInitial extends UserActionState {}

class UserActionLoading extends UserActionState {}

class UserActionSuccess extends UserActionState {
  final String userId;
  final UserActionType action;

  UserActionSuccess({
    required this.userId,
    required this.action,
  });
}

class UserActionError extends UserActionState {
  final String message;

  UserActionError(this.message);
}