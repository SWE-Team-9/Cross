part of 'auth_cubit.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);

  List<Object?> get props => [user];
}

class AuthRegisterSuccess extends AuthState {
  final User user;
  AuthRegisterSuccess(this.user);
}

class AuthProfileCompleted extends AuthState {
  final User user;
  AuthProfileCompleted(this.user);
}

class AuthEmailCheckSuccess extends AuthState {
  final bool exists;
  final String email;

  AuthEmailCheckSuccess({
    required this.exists,
    required this.email,
  });
}

class AuthVerificationEmailSent extends AuthState {
  final String email;
  AuthVerificationEmailSent(this.email);
}

class AuthEmailVerified extends AuthState {}

class AuthForgotPasswordSuccess extends AuthState {
  final String email;
  AuthForgotPasswordSuccess(this.email);
}

class AuthResetPasswordSuccess extends AuthState {}

class AuthEmailChangeRequested extends AuthAuthenticated {
  final String newEmail;

  AuthEmailChangeRequested({
    required User user,
    required this.newEmail,
  }) : super(user);
}

class AuthEmailChangeFailure extends AuthAuthenticated {
  final String message;

  AuthEmailChangeFailure({
    required User user,
    required this.message,
  }) : super(user);
}

class AuthEmailChangeConfirmed extends AuthUnauthenticated {}

class AuthError extends AuthState {
  final String message;
  final bool isNotVerified;

  AuthError(this.message, {this.isNotVerified = false});
}