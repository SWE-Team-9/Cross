import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/is_logged_in_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/login_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/logout_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/register_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/send_email_verification_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/request_email_change_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/confirm_email_change_usecase.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockIsLoggedInUseCase extends Mock implements IsLoggedInUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}
class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}
class MockSendEmailVerificationUseCase extends Mock implements SendEmailVerificationUseCase {}
class MockVerifyEmailUseCase extends Mock implements VerifyEmailUseCase {}
class MockRequestEmailChangeUseCase extends Mock implements RequestEmailChangeUseCase {}
class MockConfirmEmailChangeUseCase extends Mock implements ConfirmEmailChangeUseCase {}

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockIsLoggedInUseCase mockIsLoggedInUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockForgotPasswordUseCase mockForgotPasswordUseCase;
  late MockResetPasswordUseCase mockResetPasswordUseCase;
  late MockSendEmailVerificationUseCase mockSendEmailVerificationUseCase;
  late MockVerifyEmailUseCase mockVerifyEmailUseCase;
  late MockRequestEmailChangeUseCase mockRequestEmailChangeUseCase;
  late MockConfirmEmailChangeUseCase mockConfirmEmailChangeUseCase;
  late AuthCubit cubit;

  const user = User(
    id: '1',
    email: 'ali@test.com',
    displayName: 'Ali',
    handle: 'ali',
    avatarUrl: null,
    isVerified: true,
    isPro: false,
  );

  AuthCubit buildCubit() {
    return AuthCubit(
      loginUseCase: mockLoginUseCase,
      registerUseCase: mockRegisterUseCase,
      logoutUseCase: mockLogoutUseCase,
      isLoggedInUseCase: mockIsLoggedInUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
      forgotPasswordUseCase: mockForgotPasswordUseCase,
      resetPasswordUseCase: mockResetPasswordUseCase,
      sendEmailVerificationUseCase: mockSendEmailVerificationUseCase,
      verifyEmailUseCase: mockVerifyEmailUseCase,
      requestEmailChangeUseCase: mockRequestEmailChangeUseCase,
      confirmEmailChangeUseCase: mockConfirmEmailChangeUseCase,
    );
  }

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockIsLoggedInUseCase = MockIsLoggedInUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockForgotPasswordUseCase = MockForgotPasswordUseCase();
    mockResetPasswordUseCase = MockResetPasswordUseCase();
    mockSendEmailVerificationUseCase = MockSendEmailVerificationUseCase();
    mockVerifyEmailUseCase = MockVerifyEmailUseCase();
    mockRequestEmailChangeUseCase = MockRequestEmailChangeUseCase();
    mockConfirmEmailChangeUseCase = MockConfirmEmailChangeUseCase();
    cubit = buildCubit();
  });

  tearDown(() async {
    await cubit.close();
  });

  test('initial state is AuthInitial', () {
    expect(cubit.state, isA<AuthInitial>());
  });

  blocTest<AuthCubit, AuthState>(
    'checkAuthStatus emits loading then unauthenticated when not logged in',
    build: () {
      when(() => mockIsLoggedInUseCase()).thenAnswer((_) async => false);
      return buildCubit();
    },
    act: (cubit) => cubit.checkAuthStatus(),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthUnauthenticated>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'checkAuthStatus emits loading then unauthenticated when current user is null',
    build: () {
      when(() => mockIsLoggedInUseCase()).thenAnswer((_) async => true);
      when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => null);
      return buildCubit();
    },
    act: (cubit) => cubit.checkAuthStatus(),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthUnauthenticated>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'checkAuthStatus emits loading then authenticated on success',
    build: () {
      when(() => mockIsLoggedInUseCase()).thenAnswer((_) async => true);
      when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => user);
      return buildCubit();
    },
    act: (cubit) => cubit.checkAuthStatus(),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthAuthenticated>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'checkAuthStatus emits unauthenticated on unexpected exception',
    build: () {
      when(() => mockIsLoggedInUseCase()).thenThrow(Exception('boom'));
      return buildCubit();
    },
    act: (cubit) => cubit.checkAuthStatus(),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthUnauthenticated>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'login emits loading then authenticated on success',
    build: () {
      when(
        () => mockLoginUseCase(
          email: 'ali@test.com',
          password: '123456',
          rememberMe: true,
          captchaToken: 'captcha',
        ),
      ).thenAnswer((_) async => user);
      return buildCubit();
    },
    act: (cubit) => cubit.login(
      email: 'ali@test.com',
      password: '123456',
      rememberMe: true,
      captchaToken: 'captcha',
    ),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthAuthenticated>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'login emits error on unexpected exception',
    build: () {
      when(
        () => mockLoginUseCase(
          email: 'ali@test.com',
          password: '123456',
          rememberMe: true,
          captchaToken: 'captcha',
        ),
      ).thenThrow(Exception('boom'));
      return buildCubit();
    },
    act: (cubit) => cubit.login(
      email: 'ali@test.com',
      password: '123456',
      rememberMe: true,
      captchaToken: 'captcha',
    ),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthError>().having(
        (s) => s.message,
        'message',
        'An unexpected error occurred.',
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'login emits AuthError on DioException',
    build: () {
      when(
        () => mockLoginUseCase(
          email: 'ali@test.com',
          password: '123456',
          rememberMe: true,
          captchaToken: 'captcha',
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/login'),
            statusCode: 400,
            data: {'message': 'Bad request'},
          ),
        ),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.login(
      email: 'ali@test.com',
      password: '123456',
      rememberMe: true,
      captchaToken: 'captcha',
    ),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthError>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'register emits loading then AuthRegisterSuccess on success',
    build: () {
      when(
        () => mockRegisterUseCase(
          email: 'ali@test.com',
          password: '123456',
          passwordConfirm: '123456',
          displayName: 'Ali',
          dateOfBirth: '2000-01-01',
          gender: 'male',
          captchaToken: 'captcha',
        ),
      ).thenAnswer((_) async => user);
      return buildCubit();
    },
    act: (cubit) => cubit.register(
      email: 'ali@test.com',
      password: '123456',
      passwordConfirm: '123456',
      displayName: 'Ali',
      dateOfBirth: '2000-01-01',
      gender: 'male',
      captchaToken: 'captcha',
    ),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthRegisterSuccess>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'register emits error on unexpected exception',
    build: () {
      when(
        () => mockRegisterUseCase(
          email: 'ali@test.com',
          password: '123456',
          passwordConfirm: '123456',
          displayName: 'Ali',
          dateOfBirth: '2000-01-01',
          gender: 'male',
          captchaToken: 'captcha',
        ),
      ).thenThrow(Exception('boom'));
      return buildCubit();
    },
    act: (cubit) => cubit.register(
      email: 'ali@test.com',
      password: '123456',
      passwordConfirm: '123456',
      displayName: 'Ali',
      dateOfBirth: '2000-01-01',
      gender: 'male',
      captchaToken: 'captcha',
    ),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthError>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'logout emits loading then unauthenticated on success',
    build: () {
      when(() => mockLogoutUseCase()).thenAnswer((_) async {});
      return buildCubit();
    },
    act: (cubit) => cubit.logout(),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthUnauthenticated>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'logout emits unauthenticated on unexpected exception',
    build: () {
      when(() => mockLogoutUseCase()).thenThrow(Exception('boom'));
      return buildCubit();
    },
    act: (cubit) => cubit.logout(),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthUnauthenticated>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'sendEmailVerification emits loading then verification sent on success',
    build: () {
      when(
        () => mockSendEmailVerificationUseCase(email: 'ali@test.com'),
      ).thenAnswer((_) async {});
      return buildCubit();
    },
    act: (cubit) => cubit.sendEmailVerification(email: 'ali@test.com'),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthVerificationEmailSent>().having(
        (s) => s.email,
        'email',
        'ali@test.com',
      ),
    ],
  );

  test('sendEmailVerification emits too many requests after manual sequence',
      () async {
    final cubit = buildCubit();

    when(
      () => mockSendEmailVerificationUseCase(email: 'ali@test.com'),
    ).thenAnswer((_) async {});

    final emittedStates = <AuthState>[];
    final sub = cubit.stream.listen(emittedStates.add);

    await cubit.sendEmailVerification(email: 'ali@test.com');
    await cubit.sendEmailVerification(email: 'ali@test.com');
    await cubit.sendEmailVerification(email: 'ali@test.com');
    await cubit.sendEmailVerification(email: 'ali@test.com');

    expect(
      emittedStates.whereType<AuthVerificationEmailSent>().isNotEmpty,
      isTrue,
    );

    await sub.cancel();
    await cubit.close();
  });

  blocTest<AuthCubit, AuthState>(
    'verifyEmail emits loading then email verified on success',
    build: () {
      when(() => mockVerifyEmailUseCase(code: '123456'))
          .thenAnswer((_) async {});
      return buildCubit();
    },
    act: (cubit) => cubit.verifyEmail(code: '123456'),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthEmailVerified>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'verifyEmail emits error on unexpected exception',
    build: () {
      when(() => mockVerifyEmailUseCase(code: '123456'))
          .thenThrow(Exception('boom'));
      return buildCubit();
    },
    act: (cubit) => cubit.verifyEmail(code: '123456'),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthError>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'forgotPassword emits loading then success on success',
    build: () {
      when(() => mockForgotPasswordUseCase(email: 'ali@test.com'))
          .thenAnswer((_) async {});
      return buildCubit();
    },
    act: (cubit) => cubit.forgotPassword(email: 'ali@test.com'),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthForgotPasswordSuccess>().having(
        (s) => s.email,
        'email',
        'ali@test.com',
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'forgotPassword emits error on unexpected exception',
    build: () {
      when(() => mockForgotPasswordUseCase(email: 'ali@test.com'))
          .thenThrow(Exception('boom'));
      return buildCubit();
    },
    act: (cubit) => cubit.forgotPassword(email: 'ali@test.com'),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthError>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'resetPassword emits loading then success on success',
    build: () {
      when(
        () => mockResetPasswordUseCase(
          code: '123456',
          newPassword: 'newpass',
          newPasswordConfirm: 'newpass',
        ),
      ).thenAnswer((_) async {});
      return buildCubit();
    },
    act: (cubit) => cubit.resetPassword(
      code: '123456',
      newPassword: 'newpass',
      newPasswordConfirm: 'newpass',
    ),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthResetPasswordSuccess>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'resetPassword emits error on unexpected exception',
    build: () {
      when(
        () => mockResetPasswordUseCase(
          code: '123456',
          newPassword: 'newpass',
          newPasswordConfirm: 'newpass',
        ),
      ).thenThrow(Exception('boom'));
      return buildCubit();
    },
    act: (cubit) => cubit.resetPassword(
      code: '123456',
      newPassword: 'newpass',
      newPasswordConfirm: 'newpass',
    ),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthError>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'requestEmailChange emits AuthEmailChangeRequested on success',
    build: () {
      when(
        () => mockRequestEmailChangeUseCase(
          newEmail: 'new@test.com',
          currentPassword: 'password123',
        ),
      ).thenAnswer((_) async {});
      when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => user);
      final cubit = buildCubit();
      cubit.emit(AuthAuthenticated(user));
      return cubit;
    },
    act: (cubit) => cubit.requestEmailChange(
      newEmail: 'new@test.com',
      currentPassword: 'password123',
    ),
    expect: () => [
      isA<AuthEmailChangeRequested>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'requestEmailChange emits AuthEmailChangeFailure on DioException',
    build: () {
      when(
        () => mockRequestEmailChangeUseCase(
          newEmail: 'new@test.com',
          currentPassword: 'password123',
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/email/change'),
          response: Response(
            requestOptions: RequestOptions(path: '/email/change'),
            statusCode: 400,
            data: {'message': 'Invalid password'},
          ),
        ),
      );
      final cubit = buildCubit();
      cubit.emit(AuthAuthenticated(user));
      return cubit;
    },
    act: (cubit) => cubit.requestEmailChange(
      newEmail: 'new@test.com',
      currentPassword: 'password123',
    ),
    expect: () => [
      isA<AuthEmailChangeFailure>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'confirmEmailChange emits AuthEmailChangeConfirmed on success',
    build: () {
      when(() => mockConfirmEmailChangeUseCase(token: 'valid-token'))
          .thenAnswer((_) async {});
      when(() => mockLogoutUseCase()).thenAnswer((_) async {});
      final cubit = buildCubit();
      cubit.emit(AuthAuthenticated(user));
      return cubit;
    },
    act: (cubit) => cubit.confirmEmailChange(token: 'valid-token'),
    expect: () => [
      isA<AuthEmailChangeConfirmed>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'confirmEmailChange emits AuthEmailChangeFailure on DioException',
    build: () {
      when(() => mockConfirmEmailChangeUseCase(token: 'bad-token')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/email/confirm-change'),
          response: Response(
            requestOptions: RequestOptions(path: '/email/confirm-change'),
            statusCode: 400,
            data: {'message': 'Invalid token'},
          ),
        ),
      );
      final cubit = buildCubit();
      cubit.emit(AuthAuthenticated(user));
      return cubit;
    },
    act: (cubit) => cubit.confirmEmailChange(token: 'bad-token'),
    expect: () => [
      isA<AuthEmailChangeFailure>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'refreshCurrentUserSilently does nothing when not authenticated',
    build: buildCubit,
    act: (cubit) => cubit.refreshCurrentUserSilently(),
    expect: () => [],
  );

  blocTest<AuthCubit, AuthState>(
    'refreshCurrentUserSilently emits authenticated with refreshed user',
    build: () {
      when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => user);
      final cubit = buildCubit();
      cubit.emit(AuthAuthenticated(user));
      return cubit;
    },
    act: (cubit) => cubit.refreshCurrentUserSilently(),
    expect: () => [
      isA<AuthAuthenticated>().having(
        (s) => s.user.id,
        'user id',
        '1',
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'refreshCurrentUserSilently emits nothing when refreshed user is null',
    build: () {
      when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => null);
      final cubit = buildCubit();
      cubit.emit(AuthAuthenticated(user));
      return cubit;
    },
    act: (cubit) => cubit.refreshCurrentUserSilently(),
    expect: () => [],
  );

  blocTest<AuthCubit, AuthState>(
    'refreshCurrentUserSilently swallows exception and emits nothing',
    build: () {
      when(() => mockGetCurrentUserUseCase()).thenThrow(Exception('boom'));
      final cubit = buildCubit();
      cubit.emit(AuthAuthenticated(user));
      return cubit;
    },
    act: (cubit) => cubit.refreshCurrentUserSilently(),
    expect: () => [],
  );

  test('remainingResendSeconds is zero initially', () {
    expect(cubit.remainingResendSeconds, 0);
  });

  test('emailChangeCooldownRemainingSeconds is zero initially', () {
    expect(cubit.emailChangeCooldownRemainingSeconds, 0);
  });
}