import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/deep_links/deep_link_destination.dart';
import '../../../../core/network/error_mapper.dart';
import '../../../../core/oauth/oauth_pending_request_store.dart';
import '../../../../core/oauth/pkce_utils.dart';
import '../../../../core/oauth/windows_oauth_callback_server.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/confirm_email_change_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/is_logged_in_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/request_email_change_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/send_email_verification_usecase.dart';
import '../../domain/usecases/verify_email_usecase.dart';

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
  final RequestEmailChangeUseCase requestEmailChangeUseCase;
  final ConfirmEmailChangeUseCase confirmEmailChangeUseCase;

  final AuthRepository authRepository;
  final WindowsOAuthCallbackServer windowsOAuthCallbackServer;
  final OAuthPendingRequestStore oauthPendingRequestStore;

  int _resendCount = 0;
  DateTime? _firstResendAttempt;
  DateTime? _lastResendDateTime;

  bool _isRequestingEmailChange = false;
  DateTime? _lastEmailChangeRequestAt;

  String? _pendingOAuthState;
  String? _pendingOAuthCodeVerifier;
  String? _pendingOAuthRedirectUri;

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
    required this.requestEmailChangeUseCase,
    required this.confirmEmailChangeUseCase,
    required this.authRepository,
    required this.windowsOAuthCallbackServer,
    required this.oauthPendingRequestStore,
  }) : super(AuthInitial());

  int get remainingResendSeconds {
    if (_lastResendDateTime == null) return 0;
    final difference =
        DateTime.now().difference(_lastResendDateTime!).inSeconds;
    final remaining = 60 - difference;
    return remaining > 0 ? remaining : 0;
  }

  int get emailChangeCooldownRemainingSeconds {
    if (_lastEmailChangeRequestAt == null) return 0;
    final elapsed =
        DateTime.now().difference(_lastEmailChangeRequestAt!).inSeconds;
    final remaining = 60 - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  User? get _authenticatedUser {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.user;
    }
    return null;
  }

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
    required bool rememberMe,
    required String captchaToken,
  }) async {
    emit(AuthLoading());
    try {
      final user = await loginUseCase(
        email: email,
        password: password,
        rememberMe: rememberMe,
        captchaToken: captchaToken,
      );
      emit(AuthAuthenticated(user));
    } on DioException catch (e) {
      final failure = ErrorMapper.mapDioErrorToFailure(e);
      if (failure.message.toLowerCase().contains("verify your email")) {
        emit(AuthError(
          "Please verify your email before logging in.",
          isNotVerified: true,
        ));
      } else {
        emit(AuthError(failure.message));
      }
    } catch (e) {
      emit(AuthError('An unexpected error occurred.'));
    }
  }

  Future<void> continueWithGoogle() async {
    if (state is AuthLoading || state is AuthOAuthInProgress) return;

    emit(AuthLoading());

    try {
      final stateValue = PkceUtils.generateState();
      final codeVerifier = PkceUtils.generateCodeVerifier();
      final codeChallenge = PkceUtils.generateCodeChallenge(codeVerifier);
      final redirectUri = AppConfig.oauthRedirectUri;

      _pendingOAuthState = stateValue;
      _pendingOAuthCodeVerifier = codeVerifier;
      _pendingOAuthRedirectUri = redirectUri;

      await oauthPendingRequestStore.save(
        state: stateValue,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
      );

      final authorizeUri = authRepository.buildGoogleAuthorizeUri(
        state: stateValue,
        codeChallenge: codeChallenge,
        redirectUri: redirectUri,
      );

      if (Platform.isWindows) {
        final callbackFuture = windowsOAuthCallbackServer.waitForCallback();
        final launched = await launchUrl(
          authorizeUri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          await windowsOAuthCallbackServer.stop();
          emit(
              AuthError('Could not open the browser to continue with Google.'));
          return;
        }

        emit(AuthOAuthInProgress());

        final callbackUri = await callbackFuture;
        await handleOAuthCallbackFromUri(callbackUri);
        return;
      }

      final launched = await launchUrl(
        authorizeUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        emit(AuthError('Could not open the browser to continue with Google.'));
        return;
      }

      emit(AuthOAuthInProgress());
    } on DioException catch (e) {
      final failure = ErrorMapper.mapDioErrorToFailure(e);
      emit(AuthError(failure.message));
    } catch (e) {
      emit(AuthError('Failed to start Google sign-in.'));
    }
  }

  Future<void> handleOAuthCallbackDeepLink(
    OAuthCallbackDeepLink destination,
  ) async {
    await handleOAuthCallback(
      code: destination.code,
      state: destination.state,
      error: destination.error,
      errorDescription: destination.errorDescription,
    );
  }

  Future<void> handleOAuthCallbackFromUri(Uri uri) async {
    await handleOAuthCallback(
      code: uri.queryParameters['code'],
      state: uri.queryParameters['state'],
      error: uri.queryParameters['error'],
      errorDescription: uri.queryParameters['error_description'],
    );
  }

  Future<void> handleOAuthCallback({
    required String? code,
    required String? state,
    String? error,
    String? errorDescription,
  }) async {
    emit(AuthLoading());

    try {
      if (error != null && error.trim().isNotEmpty) {
        await _clearPendingOAuth();
        emit(AuthError(
          errorDescription?.trim().isNotEmpty == true
              ? errorDescription!.trim()
              : error.trim(),
        ));
        return;
      }

      final pending = oauthPendingRequestStore.read();

      final expectedState = _pendingOAuthState ?? pending?.state;
      final codeVerifier = _pendingOAuthCodeVerifier ?? pending?.codeVerifier;
      final redirectUri = _pendingOAuthRedirectUri ?? pending?.redirectUri;

      if (expectedState == null ||
          codeVerifier == null ||
          redirectUri == null) {
        emit(AuthError('No pending Google sign-in request was found.'));
        return;
      }

      if (code == null || code.trim().isEmpty) {
        await _clearPendingOAuth();
        emit(AuthError('OAuth callback is missing the authorization code.'));
        return;
      }

      if (state == null ||
          state.trim().isEmpty ||
          state.trim() != expectedState) {
        await _clearPendingOAuth();
        emit(AuthError('OAuth state mismatch. Please try again.'));
        return;
      }

      await authRepository.exchangeOAuthCodeForSession(
        code: code.trim(),
        redirectUri: redirectUri,
        codeVerifier: codeVerifier,
      );

      final user = await getCurrentUserUseCase();
      await _clearPendingOAuth();

      if (user == null) {
        emit(AuthError(
          'Google sign-in completed, but the session could not be loaded.',
        ));
        return;
      }

      emit(AuthAuthenticated(user));
    } on DioException catch (e) {
      await _clearPendingOAuth();
      final failure = ErrorMapper.mapDioErrorToFailure(e);
      emit(AuthError(failure.message));
    } catch (e) {
      await _clearPendingOAuth();
      emit(AuthError('Google sign-in failed. Please try again.'));
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

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await logoutUseCase();
      emit(AuthUnauthenticated());
    } on DioException catch (e) {
      final failure = ErrorMapper.mapDioErrorToFailure(e);
      emit(AuthError(failure.message));
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> sendEmailVerification({required String email}) async {
    final now = DateTime.now();
    if (remainingResendSeconds > 0) return;

    if (_firstResendAttempt != null) {
      final difference = now.difference(_firstResendAttempt!);
      if (difference.inMinutes < 1) {
        if (_resendCount >= 3) {
          emit(AuthError(
              "Too many requests. Please wait a minute before trying again."));
          return;
        }
      } else {
        _resendCount = 0;
        _firstResendAttempt = now;
      }
    } else {
      _firstResendAttempt = now;
    }

    emit(AuthLoading());
    try {
      await sendEmailVerificationUseCase(email: email);
      _resendCount++;
      _lastResendDateTime = DateTime.now();
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

  Future<void> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  }) async {
    final currentUser = _authenticatedUser;

    if (_isRequestingEmailChange) return;

    final remaining = emailChangeCooldownRemainingSeconds;
    if (remaining > 0) {
      final message =
          'Please wait $remaining seconds before sending another link.';
      if (currentUser != null) {
        emit(AuthEmailChangeFailure(user: currentUser, message: message));
      } else {
        emit(AuthError(message));
      }
      return;
    }

    _isRequestingEmailChange = true;

    try {
      final normalizedEmail = newEmail.trim().toLowerCase();
      await requestEmailChangeUseCase(
        newEmail: normalizedEmail,
        currentPassword: currentPassword,
      );

      _lastEmailChangeRequestAt = DateTime.now();

      if (currentUser != null) {
        emit(AuthEmailChangeRequested(
          user: currentUser,
          newEmail: normalizedEmail,
        ));
        return;
      }

      final refreshedUser = await getCurrentUserUseCase();
      if (refreshedUser != null) {
        emit(AuthEmailChangeRequested(
          user: refreshedUser,
          newEmail: normalizedEmail,
        ));
      } else {
        emit(AuthError(
            'Email change request succeeded, but user refresh failed.'));
      }
    } on DioException catch (e) {
      final failure = ErrorMapper.mapDioErrorToFailure(e);
      if (currentUser != null) {
        emit(AuthEmailChangeFailure(
          user: currentUser,
          message: failure.message,
        ));
      } else {
        emit(AuthError(failure.message));
      }
    } catch (e) {
      if (currentUser != null) {
        emit(AuthEmailChangeFailure(
          user: currentUser,
          message: 'An unexpected error occurred.',
        ));
      } else {
        emit(AuthError('An unexpected error occurred.'));
      }
    } finally {
      _isRequestingEmailChange = false;
    }
  }

  Future<void> confirmEmailChange({required String token}) async {
    final currentUser = _authenticatedUser;
    try {
      await confirmEmailChangeUseCase(token: token);
      await logoutUseCase();
      emit(AuthEmailChangeConfirmed());
    } on DioException catch (e) {
      final failure = ErrorMapper.mapDioErrorToFailure(e);
      if (currentUser != null) {
        emit(AuthEmailChangeFailure(
          user: currentUser,
          message: failure.message,
        ));
      } else {
        emit(AuthError(failure.message));
      }
    } catch (e) {
      if (currentUser != null) {
        emit(AuthEmailChangeFailure(
          user: currentUser,
          message: 'An unexpected error occurred.',
        ));
      } else {
        emit(AuthError('An unexpected error occurred.'));
      }
    }
  }

  Future<void> refreshCurrentUserSilently() async {
    if (state is! AuthAuthenticated) return;
    try {
      final user = await getCurrentUserUseCase();
      if (user != null) {
        emit(AuthAuthenticated(user));
      }
    } catch (_) {}
  }

  Future<void> _clearPendingOAuth() async {
    _pendingOAuthState = null;
    _pendingOAuthCodeVerifier = null;
    _pendingOAuthRedirectUri = null;
    await oauthPendingRequestStore.clear();
  }
}
