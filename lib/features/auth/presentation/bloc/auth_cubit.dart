import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/is_logged_in_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/send_email_verification_usecase.dart';
import '../../domain/usecases/verify_email_usecase.dart';
import '../../../../core/network/error_mapper.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final IsLoggedInUseCase isLoggedInUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final SendEmailVerificationUseCase sendEmailVerificationUseCase;
  final VerifyEmailUseCase verifyEmailUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.registerUseCase,
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

  Future<void> login({
    required String email,
    required String password,
    required String captchaToken,
  }) async {
    emit(AuthLoading());
    try {
      final user = await loginUseCase(
        email: email,
        password: password,
        captchaToken: captchaToken,
      );
      emit(AuthAuthenticated(user));
    } on DioException catch (e) {
      final failure = ErrorMapper.mapDioErrorToFailure(e);
      emit(AuthError(failure.message));
    } catch (e) {
      emit(AuthError('An unexpected error occurred.'));
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String passwordConfirm,
    required String displayName,
    required String dateOfBirth,
    required String gender,
    required String captchaToken,
  }) async {
    emit(AuthLoading());
    try {
      final user = await registerUseCase(
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        displayName: displayName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        captchaToken: captchaToken,
      );
      emit(AuthRegisterSuccess(user));
    } on DioException catch (e) {
      final failure = ErrorMapper.mapDioErrorToFailure(e);
      emit(AuthError(failure.message));
    } catch (e) {
      emit(AuthError('An unexpected error occurred.'));
    }
  }

  Future<void> sendEmailVerification({required String email}) async {
    emit(AuthLoading());
    try {
      await sendEmailVerificationUseCase(email: email);
      emit(AuthVerificationEmailSent(email));
    } on DioException catch (e) {
      final failure = ErrorMapper.mapDioErrorToFailure(e);
      emit(AuthError(failure.message));
    } catch (e) {
      emit(AuthError('An unexpected error occurred.'));
    }
  }

  Future<void> verifyEmail({required String code}) async {
    emit(AuthLoading());
    try {
      await verifyEmailUseCase(code: code);
      emit(AuthEmailVerified());
    } on DioException catch (e) {
      final failure = ErrorMapper.mapDioErrorToFailure(e);
      emit(AuthError(failure.message));
    } catch (e) {
      emit(AuthError('An unexpected error occurred.'));
    }
  }

  Future<void> forgotPassword({required String email}) async {
    emit(AuthLoading());
    try {
      await forgotPasswordUseCase(email: email);
      emit(AuthForgotPasswordSuccess(email));
    } on DioException catch (e) {
      final failure = ErrorMapper.mapDioErrorToFailure(e);
      emit(AuthError(failure.message));
    } catch (e) {
      emit(AuthError('An unexpected error occurred.'));
    }
  }

  Future<void> resetPassword({
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  }) async {
    emit(AuthLoading());
    try {
      await resetPasswordUseCase(
        code: code,
        newPassword: newPassword,
        newPasswordConfirm: newPasswordConfirm,
      );
      emit(AuthResetPasswordSuccess());
    } on DioException catch (e) {
      final failure = ErrorMapper.mapDioErrorToFailure(e);
      emit(AuthError(failure.message));
    } catch (e) {
      emit(AuthError('An unexpected error occurred.'));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await logoutUseCase();
      emit(AuthUnauthenticated());
    } catch (e) {
      final failure = ErrorMapper.mapDioErrorToFailure(e as DioException);
      emit(AuthError(failure.message));
    }
  }
}
