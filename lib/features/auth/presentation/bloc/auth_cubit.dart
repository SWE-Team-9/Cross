import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/check_email_exists_usecase.dart';
import '../../domain/usecases/complete_profile_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/is_logged_in_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/send_email_verification_usecase.dart';
import '../../domain/usecases/verify_email_usecase.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final CheckEmailExistsUseCase checkEmailExistsUseCase;
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final CompleteProfileUseCase completeProfileUseCase;
  final LogoutUseCase logoutUseCase;
  final IsLoggedInUseCase isLoggedInUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final SendEmailVerificationUseCase sendEmailVerificationUseCase;
  final VerifyEmailUseCase verifyEmailUseCase;

  AuthCubit({
    required this.checkEmailExistsUseCase,
    required this.loginUseCase,
    required this.registerUseCase,
    required this.completeProfileUseCase,
    required this.logoutUseCase,
    required this.isLoggedInUseCase,
    required this.getCurrentUserUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUseCase,
    required this.sendEmailVerificationUseCase,
    required this.verifyEmailUseCase,
  }) : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());

    try {
      final loggedIn = await isLoggedInUseCase();

      if (!loggedIn) {
        emit(AuthUnauthenticated());
        return;
      }

      final user = await getCurrentUserUseCase();

      if (user == null) {
        emit(AuthUnauthenticated());
        return;
      }

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> checkEmail({
    required String email,
  }) async {
    emit(AuthLoading());

    try {
      final exists = await checkEmailExistsUseCase(email: email);
      emit(AuthEmailCheckSuccess(
        exists: exists,
        email: email,
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());

    try {
      final user = await loginUseCase(
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());

    try {
      final user = await registerUseCase(
        email: email,
        password: password,
      );
      emit(AuthRegisterSuccess(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> sendEmailVerification({
    required String email,
  }) async {
    emit(AuthLoading());

    try {
      await sendEmailVerificationUseCase(email: email);
      emit(AuthVerificationEmailSent(email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    emit(AuthLoading());

    try {
      await verifyEmailUseCase(
        email: email,
        code: code,
      );
      emit(AuthEmailVerified());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> forgotPassword({
    required String email,
  }) async {
    emit(AuthLoading());

    try {
      await forgotPasswordUseCase(email: email);
      emit(AuthForgotPasswordSuccess(email));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    emit(AuthLoading());

    try {
      await resetPasswordUseCase(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      emit(AuthResetPasswordSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> completeProfile({
    required String displayName,
    required int birthMonth,
    required int birthDay,
    required int birthYear,
    required String gender,
  }) async {
    emit(AuthLoading());

    try {
      final user = await completeProfileUseCase(
        displayName: displayName,
        birthMonth: birthMonth,
        birthDay: birthDay,
        birthYear: birthYear,
        gender: gender,
      );
      emit(AuthProfileCompleted(user));
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());

    try {
      await logoutUseCase();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
