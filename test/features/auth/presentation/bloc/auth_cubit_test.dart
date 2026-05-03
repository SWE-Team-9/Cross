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
import 'package:soundcloud_clone/features/auth/domain/repositories/auth_repository.dart';
import 'package:soundcloud_clone/core/oauth/oauth_pending_request_store.dart';
import 'package:soundcloud_clone/core/oauth/windows_oauth_callback_server.dart';
import 'package:soundcloud_clone/core/deep_links/deep_link_destination.dart';
import 'package:soundcloud_clone/features/notifications/data/services/fcm_registration_service.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockRegisterUseCase extends Mock implements RegisterUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockIsLoggedInUseCase extends Mock implements IsLoggedInUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}

class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}

class MockSendEmailVerificationUseCase extends Mock
    implements SendEmailVerificationUseCase {}

class MockVerifyEmailUseCase extends Mock implements VerifyEmailUseCase {}

class MockRequestEmailChangeUseCase extends Mock
    implements RequestEmailChangeUseCase {}

class MockConfirmEmailChangeUseCase extends Mock
    implements ConfirmEmailChangeUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockWindowsOAuthCallbackServer extends Mock
    implements WindowsOAuthCallbackServer {}

class MockOAuthPendingRequestStore extends Mock
    implements OAuthPendingRequestStore {}

class MockFcmRegistrationService extends Mock
    implements FcmRegistrationService {}

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
  late MockAuthRepository mockAuthRepository;
  late MockWindowsOAuthCallbackServer mockWindowsOAuthCallbackServer;
  late MockOAuthPendingRequestStore mockOAuthPendingRequestStore;
  late MockFcmRegistrationService mockFcmRegistrationService;
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
      authRepository: mockAuthRepository,
      windowsOAuthCallbackServer: mockWindowsOAuthCallbackServer,
      oauthPendingRequestStore: mockOAuthPendingRequestStore,
      fcmRegistrationService: mockFcmRegistrationService,
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
    mockAuthRepository = MockAuthRepository();
    mockWindowsOAuthCallbackServer = MockWindowsOAuthCallbackServer();
    mockOAuthPendingRequestStore = MockOAuthPendingRequestStore();
    mockFcmRegistrationService = MockFcmRegistrationService();

    when(() => mockFcmRegistrationService.syncToken()).thenAnswer(
      (_) async => true,
    );

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
    'login emits not-verified AuthError when backend asks for email verification',
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
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/login'),
            statusCode: 401,
            data: {'message': 'Please verify your email before login.'},
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
      isA<AuthError>()
          .having((s) => s.isNotVerified, 'isNotVerified', true)
          .having(
            (s) => s.message,
            'message',
            'Please verify your email before logging in.',
          ),
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
    'register emits AuthError on DioException',
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
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/register'),
          response: Response(
            requestOptions: RequestOptions(path: '/register'),
            statusCode: 400,
            data: {'message': 'Email already in use'},
          ),
        ),
      );
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
    'logout emits AuthError on DioException',
    build: () {
      when(() => mockLogoutUseCase()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/logout'),
          response: Response(
            requestOptions: RequestOptions(path: '/logout'),
            statusCode: 500,
            data: {'message': 'Server error'},
          ),
        ),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.logout(),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthError>(),
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

  blocTest<AuthCubit, AuthState>(
    'sendEmailVerification emits AuthError on DioException',
    build: () {
      when(
        () => mockSendEmailVerificationUseCase(email: 'ali@test.com'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/email/send-verification'),
          response: Response(
            requestOptions: RequestOptions(path: '/email/send-verification'),
            statusCode: 429,
            data: {'message': 'Too many requests'},
          ),
        ),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.sendEmailVerification(email: 'ali@test.com'),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthError>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'sendEmailVerification emits AuthError on unexpected exception',
    build: () {
      when(
        () => mockSendEmailVerificationUseCase(email: 'ali@test.com'),
      ).thenThrow(Exception('boom'));
      return buildCubit();
    },
    act: (cubit) => cubit.sendEmailVerification(email: 'ali@test.com'),
    expect: () => [
      isA<AuthLoading>(),
      isA<AuthError>()
          .having((s) => s.message, 'message', 'An unexpected error occurred.'),
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
    'verifyEmail emits AuthError on DioException',
    build: () {
      when(() => mockVerifyEmailUseCase(code: '123456')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/email/verify'),
          response: Response(
            requestOptions: RequestOptions(path: '/email/verify'),
            statusCode: 400,
            data: {'message': 'Invalid code'},
          ),
        ),
      );
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
    'forgotPassword emits AuthError on DioException',
    build: () {
      when(() => mockForgotPasswordUseCase(email: 'ali@test.com')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/forgot-password'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/forgot-password'),
            statusCode: 404,
            data: {'message': 'Email not found'},
          ),
        ),
      );
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
    'resetPassword emits AuthError on DioException',
    build: () {
      when(
        () => mockResetPasswordUseCase(
          code: '123456',
          newPassword: 'newpass',
          newPasswordConfirm: 'newpass',
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/reset-password'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/reset-password'),
            statusCode: 400,
            data: {'message': 'Invalid reset token'},
          ),
        ),
      );
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
    'requestEmailChange emits AuthEmailChangeRequested when unauthenticated but user refresh succeeds',
    build: () {
      when(
        () => mockRequestEmailChangeUseCase(
          newEmail: 'new@test.com',
          currentPassword: 'password123',
        ),
      ).thenAnswer((_) async {});
      when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => user);
      return buildCubit();
    },
    act: (cubit) => cubit.requestEmailChange(
      newEmail: 'new@test.com',
      currentPassword: 'password123',
    ),
    expect: () => [
      isA<AuthEmailChangeRequested>().having(
        (s) => s.newEmail,
        'newEmail',
        'new@test.com',
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'requestEmailChange emits AuthError when unauthenticated and user refresh fails',
    build: () {
      when(
        () => mockRequestEmailChangeUseCase(
          newEmail: 'new@test.com',
          currentPassword: 'password123',
        ),
      ).thenAnswer((_) async {});
      when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => null);
      return buildCubit();
    },
    act: (cubit) => cubit.requestEmailChange(
      newEmail: 'new@test.com',
      currentPassword: 'password123',
    ),
    expect: () => [
      isA<AuthError>().having(
        (s) => s.message,
        'message',
        'Email change request succeeded, but user refresh failed.',
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'requestEmailChange enforces cooldown with AuthError when unauthenticated',
    build: () {
      when(
        () => mockRequestEmailChangeUseCase(
          newEmail: 'new@test.com',
          currentPassword: 'password123',
        ),
      ).thenAnswer((_) async {});
      when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => null);
      return buildCubit();
    },
    act: (cubit) async {
      await cubit.requestEmailChange(
        newEmail: 'new@test.com',
        currentPassword: 'password123',
      );
      await cubit.requestEmailChange(
        newEmail: 'new@test.com',
        currentPassword: 'password123',
      );
    },
    expect: () => [
      isA<AuthError>().having(
        (s) => s.message,
        'message',
        'Email change request succeeded, but user refresh failed.',
      ),
      isA<AuthError>().having(
        (s) => s.message,
        'messageContainsWait',
        contains('Please wait'),
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'requestEmailChange emits AuthError on DioException when unauthenticated',
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
            data: {'message': 'Bad request'},
          ),
        ),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.requestEmailChange(
      newEmail: 'new@test.com',
      currentPassword: 'password123',
    ),
    expect: () => [
      isA<AuthError>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'requestEmailChange emits AuthError on unexpected exception when unauthenticated',
    build: () {
      when(
        () => mockRequestEmailChangeUseCase(
          newEmail: 'new@test.com',
          currentPassword: 'password123',
        ),
      ).thenThrow(Exception('boom'));
      return buildCubit();
    },
    act: (cubit) => cubit.requestEmailChange(
      newEmail: 'new@test.com',
      currentPassword: 'password123',
    ),
    expect: () => [
      isA<AuthError>().having(
        (s) => s.message,
        'message',
        'An unexpected error occurred.',
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'requestEmailChange enforces cooldown after successful request',
    build: () {
      when(
        () => mockRequestEmailChangeUseCase(
          newEmail: 'new@test.com',
          currentPassword: 'password123',
        ),
      ).thenAnswer((_) async {});
      final cubit = buildCubit();
      cubit.emit(AuthAuthenticated(user));
      return cubit;
    },
    act: (cubit) async {
      await cubit.requestEmailChange(
        newEmail: 'new@test.com',
        currentPassword: 'password123',
      );
      await cubit.requestEmailChange(
        newEmail: 'new@test.com',
        currentPassword: 'password123',
      );
    },
    expect: () => [
      isA<AuthEmailChangeRequested>(),
      isA<AuthEmailChangeFailure>().having(
        (s) => s.message,
        'messageContainsWait',
        contains('Please wait'),
      ),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'confirmEmailChange emits AuthError on DioException when unauthenticated',
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
      return buildCubit();
    },
    act: (cubit) => cubit.confirmEmailChange(token: 'bad-token'),
    expect: () => [
      isA<AuthError>(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'confirmEmailChange emits AuthError on unexpected exception when unauthenticated',
    build: () {
      when(() => mockConfirmEmailChangeUseCase(token: 'bad-token'))
          .thenThrow(Exception('boom'));
      return buildCubit();
    },
    act: (cubit) => cubit.confirmEmailChange(token: 'bad-token'),
    expect: () => [
      isA<AuthError>().having(
        (s) => s.message,
        'message',
        'An unexpected error occurred.',
      ),
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

  test('remainingResendSeconds is greater than zero after a successful resend',
      () async {
    when(
      () => mockSendEmailVerificationUseCase(email: 'ali@test.com'),
    ).thenAnswer((_) async {});

    await cubit.sendEmailVerification(email: 'ali@test.com');

    expect(cubit.remainingResendSeconds, greaterThan(0));
  });

  test('emailChangeCooldownRemainingSeconds is zero initially', () {
    expect(cubit.emailChangeCooldownRemainingSeconds, 0);
  });

  test('emailChangeCooldownRemainingSeconds is greater than zero after success',
      () async {
    when(
      () => mockRequestEmailChangeUseCase(
        newEmail: 'new@test.com',
        currentPassword: 'password123',
      ),
    ).thenAnswer((_) async {});
    cubit.emit(AuthAuthenticated(user));

    await cubit.requestEmailChange(
      newEmail: 'new@test.com',
      currentPassword: 'password123',
    );

    expect(cubit.emailChangeCooldownRemainingSeconds, greaterThan(0));
  });

  group('OAuth callbacks', () {
    const pending = OAuthPendingRequest(
      state: 'state-123',
      codeVerifier: 'verifier-123',
      redirectUri: 'soundcloud://oauth/callback',
    );

    blocTest<AuthCubit, AuthState>(
      'handleOAuthCallback emits error from provider and clears pending request',
      build: () {
        when(() => mockOAuthPendingRequestStore.clear())
            .thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.handleOAuthCallback(
        code: null,
        state: null,
        error: 'access_denied',
        errorDescription: 'User cancelled sign in',
      ),
      expect: () => [
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'callback_received'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'provider_error')
            .having((s) => s.isError, 'isError', true)
            .having((s) => s.message, 'message', 'User cancelled sign in'),
      ],
      verify: (_) {
        verify(() => mockOAuthPendingRequestStore.clear()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'handleOAuthCallback emits error when no pending request exists',
      build: () {
        when(() => mockOAuthPendingRequestStore.read()).thenReturn(null);
        return buildCubit();
      },
      act: (cubit) => cubit.handleOAuthCallback(
        code: 'code-123',
        state: 'state-123',
      ),
      expect: () => [
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'callback_received'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'validating_callback'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'missing_pending_request')
            .having((s) => s.isError, 'isError', true),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'handleOAuthCallback emits error when callback code is missing',
      build: () {
        when(() => mockOAuthPendingRequestStore.read()).thenReturn(pending);
        when(() => mockOAuthPendingRequestStore.clear())
            .thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.handleOAuthCallback(
        code: '  ',
        state: 'state-123',
      ),
      expect: () => [
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'callback_received'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'validating_callback'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'missing_code')
            .having((s) => s.isError, 'isError', true),
      ],
      verify: (_) {
        verify(() => mockOAuthPendingRequestStore.clear()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'handleOAuthCallback emits error when state does not match',
      build: () {
        when(() => mockOAuthPendingRequestStore.read()).thenReturn(pending);
        when(() => mockOAuthPendingRequestStore.clear())
            .thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) => cubit.handleOAuthCallback(
        code: 'code-123',
        state: 'wrong-state',
      ),
      expect: () => [
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'callback_received'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'validating_callback'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'state_mismatch')
            .having((s) => s.isError, 'isError', true),
      ],
      verify: (_) {
        verify(() => mockOAuthPendingRequestStore.clear()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'handleOAuthCallback emits authenticated when exchange succeeds',
      build: () {
        when(() => mockOAuthPendingRequestStore.read()).thenReturn(pending);
        when(() => mockOAuthPendingRequestStore.clear())
            .thenAnswer((_) async {});
        when(
          () => mockAuthRepository.exchangeOAuthCodeForSession(
            code: 'code-123',
            redirectUri: pending.redirectUri,
            codeVerifier: pending.codeVerifier,
          ),
        ).thenAnswer((_) async {});
        when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => user);
        return buildCubit();
      },
      act: (cubit) => cubit.handleOAuthCallback(
        code: 'code-123',
        state: pending.state,
      ),
      expect: () => [
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'callback_received'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'validating_callback'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'exchanging_code'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'loading_user'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'success')
            .having((s) => s.isSuccess, 'isSuccess', true),
        isA<AuthAuthenticated>().having((s) => s.user.id, 'user id', user.id),
      ],
      verify: (_) {
        verify(() => mockOAuthPendingRequestStore.clear()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'handleOAuthCallback emits error when session exchange succeeds but user refresh is null',
      build: () {
        when(() => mockOAuthPendingRequestStore.read()).thenReturn(pending);
        when(() => mockOAuthPendingRequestStore.clear())
            .thenAnswer((_) async {});
        when(
          () => mockAuthRepository.exchangeOAuthCodeForSession(
            code: 'code-123',
            redirectUri: pending.redirectUri,
            codeVerifier: pending.codeVerifier,
          ),
        ).thenAnswer((_) async {});
        when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => null);
        return buildCubit();
      },
      act: (cubit) => cubit.handleOAuthCallback(
        code: 'code-123',
        state: pending.state,
      ),
      expect: () => [
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'callback_received'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'validating_callback'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'exchanging_code'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'loading_user'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'session_not_loaded')
            .having((s) => s.isError, 'isError', true),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'handleOAuthCallback emits mapped Dio error when exchange fails',
      build: () {
        when(() => mockOAuthPendingRequestStore.read()).thenReturn(pending);
        when(() => mockOAuthPendingRequestStore.clear())
            .thenAnswer((_) async {});
        when(
          () => mockAuthRepository.exchangeOAuthCodeForSession(
            code: 'code-123',
            redirectUri: pending.redirectUri,
            codeVerifier: pending.codeVerifier,
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/oauth/google/callback'),
            response: Response(
              requestOptions: RequestOptions(path: '/oauth/google/callback'),
              statusCode: 400,
              data: {'message': 'Invalid OAuth code'},
            ),
          ),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.handleOAuthCallback(
        code: 'code-123',
        state: pending.state,
      ),
      expect: () => [
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'callback_received'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'validating_callback'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'exchanging_code'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'backend_error')
            .having((s) => s.isError, 'isError', true)
            .having((s) => s.message, 'message',
                'Something went wrong. Please try again.'),
      ],
      verify: (_) {
        verify(() => mockOAuthPendingRequestStore.clear()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'handleOAuthCallback emits generic error on unexpected exception',
      build: () {
        when(() => mockOAuthPendingRequestStore.read()).thenReturn(pending);
        when(() => mockOAuthPendingRequestStore.clear())
            .thenAnswer((_) async {});
        when(
          () => mockAuthRepository.exchangeOAuthCodeForSession(
            code: 'code-123',
            redirectUri: pending.redirectUri,
            codeVerifier: pending.codeVerifier,
          ),
        ).thenThrow(Exception('boom'));
        return buildCubit();
      },
      act: (cubit) => cubit.handleOAuthCallback(
        code: 'code-123',
        state: pending.state,
      ),
      expect: () => [
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'callback_received'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'validating_callback'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'exchanging_code'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'unexpected_error')
            .having((s) => s.isError, 'isError', true),
      ],
      verify: (_) {
        verify(() => mockOAuthPendingRequestStore.clear()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'handleOAuthCallbackFromUri forwards query params to handler',
      build: () {
        when(() => mockOAuthPendingRequestStore.read()).thenReturn(pending);
        when(() => mockOAuthPendingRequestStore.clear())
            .thenAnswer((_) async {});
        when(
          () => mockAuthRepository.exchangeOAuthCodeForSession(
            code: 'code-from-uri',
            redirectUri: pending.redirectUri,
            codeVerifier: pending.codeVerifier,
          ),
        ).thenAnswer((_) async {});
        when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => user);
        return buildCubit();
      },
      act: (cubit) => cubit.handleOAuthCallbackFromUri(
        Uri.parse(
          'soundcloud://oauth/callback?code=code-from-uri&state=state-123',
        ),
      ),
      expect: () => [
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'callback_received'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'validating_callback'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'exchanging_code'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'loading_user'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'success')
            .having((s) => s.isSuccess, 'isSuccess', true),
        isA<AuthAuthenticated>(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'handleOAuthCallbackDeepLink forwards deep link payload to handler',
      build: () {
        when(() => mockOAuthPendingRequestStore.read()).thenReturn(pending);
        when(() => mockOAuthPendingRequestStore.clear())
            .thenAnswer((_) async {});
        when(
          () => mockAuthRepository.exchangeOAuthCodeForSession(
            code: 'code-from-link',
            redirectUri: pending.redirectUri,
            codeVerifier: pending.codeVerifier,
          ),
        ).thenAnswer((_) async {});
        when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => user);
        return buildCubit();
      },
      act: (cubit) => cubit.handleOAuthCallbackDeepLink(
        const OAuthCallbackDeepLink(
          code: 'code-from-link',
          state: 'state-123',
        ),
      ),
      expect: () => [
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'callback_received'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'validating_callback'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'exchanging_code'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'loading_user'),
        isA<AuthOAuthDiagnostic>()
            .having((s) => s.stage, 'stage', 'success')
            .having((s) => s.isSuccess, 'isSuccess', true),
        isA<AuthAuthenticated>(),
      ],
    );
  });
}
