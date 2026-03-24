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
  late AuthCubit cubit;

  const tUser = User(
    id: '1',
    email: 'ali@example.com',
    handle: 'ali',
    displayName: 'Ali',
    avatarUrl: null,
  );

  DioException dioError({
    required DioExceptionType type,
    int? statusCode,
    Map<String, dynamic>? data,
    String? message,
  }) {
    return DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: type,
      message: message,
      response: statusCode == null
          ? null
          : Response<dynamic>(
              requestOptions: RequestOptions(path: '/test'),
              statusCode: statusCode,
              data: data,
            ),
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

    cubit = AuthCubit(
      loginUseCase: mockLoginUseCase,
      registerUseCase: mockRegisterUseCase,
      logoutUseCase: mockLogoutUseCase,
      isLoggedInUseCase: mockIsLoggedInUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
      forgotPasswordUseCase: mockForgotPasswordUseCase,
      resetPasswordUseCase: mockResetPasswordUseCase,
      sendEmailVerificationUseCase: mockSendEmailVerificationUseCase,
      verifyEmailUseCase: mockVerifyEmailUseCase,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('checkAuthStatus', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when user is not logged in',
      build: () {
        when(() => mockIsLoggedInUseCase()).thenAnswer((_) async => false);
        return cubit;
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when current user is null',
      build: () {
        when(() => mockIsLoggedInUseCase()).thenAnswer((_) async => true);
        when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => null);
        return cubit;
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when logged in and user exists',
      build: () {
        when(() => mockIsLoggedInUseCase()).thenAnswer((_) async => true);
        when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => tUser);
        return cubit;
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>()
            .having((s) => s.user.email, 'email', 'ali@example.com'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] on unexpected error',
      build: () {
        when(() => mockIsLoggedInUseCase()).thenThrow(Exception('boom'));
        return cubit;
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );
  });

  group('login', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on success',
      build: () {
        when(
          () => mockLoginUseCase(
            email: 'ali@example.com',
            password: 'Pass@123',
            captchaToken: 'captcha',
          ),
        ).thenAnswer((_) async => tUser);
        return cubit;
      },
      act: (cubit) => cubit.login(
        email: 'ali@example.com',
        password: 'Pass@123',
        captchaToken: 'captcha',
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having((s) => s.user.handle, 'handle', 'ali'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthError with isNotVerified=true when backend asks for email verification',
      build: () {
        when(
          () => mockLoginUseCase(
            email: 'ali@example.com',
            password: 'Pass@123',
            captchaToken: 'captcha',
          ),
        ).thenThrow(
          dioError(
            type: DioExceptionType.badResponse,
            statusCode: 401,
            data: {'message': 'Please verify your email before logging in.'},
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.login(
        email: 'ali@example.com',
        password: 'Pass@123',
        captchaToken: 'captcha',
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>()
            .having((s) => s.message, 'message',
                'Please verify your email before logging in.')
            .having((s) => s.isNotVerified, 'isNotVerified', true),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthError with mapped Dio message on non-verification failure',
      build: () {
        when(
          () => mockLoginUseCase(
            email: 'ali@example.com',
            password: 'wrong',
            captchaToken: 'captcha',
          ),
        ).thenThrow(
          dioError(
            type: DioExceptionType.badResponse,
            statusCode: 401,
            data: {'message': 'Wrong Email or Password'},
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.login(
        email: 'ali@example.com',
        password: 'wrong',
        captchaToken: 'captcha',
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>()
            .having((s) => s.message, 'message', 'Wrong Email or Password')
            .having((s) => s.isNotVerified, 'isNotVerified', false),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits generic AuthError on unexpected exception',
      build: () {
        when(
          () => mockLoginUseCase(
            email: 'ali@example.com',
            password: 'Pass@123',
            captchaToken: 'captcha',
          ),
        ).thenThrow(Exception('boom'));
        return cubit;
      },
      act: (cubit) => cubit.login(
        email: 'ali@example.com',
        password: 'Pass@123',
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
  });

  group('register', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthRegisterSuccess] on success',
      build: () {
        when(
          () => mockRegisterUseCase(
            email: 'ali@example.com',
            password: 'Pass@123',
            passwordConfirm: 'Pass@123',
            displayName: 'Ali',
            dateOfBirth: '2000-01-01',
            gender: 'male',
            captchaToken: 'captcha',
          ),
        ).thenAnswer((_) async => tUser);
        return cubit;
      },
      act: (cubit) => cubit.register(
        email: 'ali@example.com',
        password: 'Pass@123',
        passwordConfirm: 'Pass@123',
        displayName: 'Ali',
        dateOfBirth: '2000-01-01',
        gender: 'male',
        captchaToken: 'captcha',
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthRegisterSuccess>()
            .having((s) => s.user.email, 'email', 'ali@example.com'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthError on DioException',
      build: () {
        when(
          () => mockRegisterUseCase(
            email: 'ali@example.com',
            password: 'Pass@123',
            passwordConfirm: 'Pass@123',
            displayName: 'Ali',
            dateOfBirth: '2000-01-01',
            gender: 'male',
            captchaToken: 'captcha',
          ),
        ).thenThrow(
          dioError(
            type: DioExceptionType.badResponse,
            statusCode: 400,
            data: {'message': 'Email already exists'},
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.register(
        email: 'ali@example.com',
        password: 'Pass@123',
        passwordConfirm: 'Pass@123',
        displayName: 'Ali',
        dateOfBirth: '2000-01-01',
        gender: 'male',
        captchaToken: 'captcha',
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>()
            .having((s) => s.message, 'message', 'Email already exists'),
      ],
    );
  });

  group('logout', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] on success',
      build: () {
        when(() => mockLogoutUseCase()).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthError on DioException',
      build: () {
        when(() => mockLogoutUseCase()).thenThrow(
          dioError(
            type: DioExceptionType.badResponse,
            statusCode: 500,
            data: {'message': 'Server error'},
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthUnauthenticated on unexpected exception',
      build: () {
        when(() => mockLogoutUseCase()).thenThrow(Exception('boom'));
        return cubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );
  });

  group('sendEmailVerification', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthVerificationEmailSent] on success',
      build: () {
        when(() => mockSendEmailVerificationUseCase(email: 'ali@example.com'))
            .thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.sendEmailVerification(email: 'ali@example.com'),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthVerificationEmailSent>()
            .having((s) => s.email, 'email', 'ali@example.com'),
      ],
      verify: (_) {
        expect(cubit.remainingResendSeconds, inInclusiveRange(1, 60));
      },
    );

    blocTest<AuthCubit, AuthState>(
      'does nothing when cooldown is active',
      build: () {
        when(() => mockSendEmailVerificationUseCase(email: 'ali@example.com'))
            .thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) async {
        await cubit.sendEmailVerification(email: 'ali@example.com');
        await cubit.sendEmailVerification(email: 'ali@example.com');
      },
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthVerificationEmailSent>(),
      ],
      verify: (_) {
        verify(() => mockSendEmailVerificationUseCase(email: 'ali@example.com'))
            .called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthError on DioException',
      build: () {
        when(() => mockSendEmailVerificationUseCase(email: 'ali@example.com'))
            .thenThrow(
          dioError(
            type: DioExceptionType.badResponse,
            statusCode: 400,
            data: {'message': 'Cannot send verification email'},
          ),
        );
        return cubit;
      },
      act: (cubit) => cubit.sendEmailVerification(email: 'ali@example.com'),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          'Cannot send verification email',
        ),
      ],
    );
  });

  group('verifyEmail', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthEmailVerified] on success',
      build: () {
        when(() => mockVerifyEmailUseCase(code: '123456'))
            .thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.verifyEmail(code: '123456'),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthEmailVerified>(),
      ],
    );
  });

  group('forgotPassword', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthForgotPasswordSuccess] on success',
      build: () {
        when(() => mockForgotPasswordUseCase(email: 'ali@example.com'))
            .thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.forgotPassword(email: 'ali@example.com'),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthForgotPasswordSuccess>()
            .having((s) => s.email, 'email', 'ali@example.com'),
      ],
    );
  });

  group('resetPassword', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthResetPasswordSuccess] on success',
      build: () {
        when(
          () => mockResetPasswordUseCase(
            code: '123456',
            newPassword: 'NewPass@123',
            newPasswordConfirm: 'NewPass@123',
          ),
        ).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.resetPassword(
        code: '123456',
        newPassword: 'NewPass@123',
        newPasswordConfirm: 'NewPass@123',
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthResetPasswordSuccess>(),
      ],
    );
  });

  group('refreshCurrentUserSilently', () {
    blocTest<AuthCubit, AuthState>(
      'does nothing when current state is not authenticated',
      build: () {
        when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => tUser);
        return cubit;
      },
      act: (cubit) => cubit.refreshCurrentUserSilently(),
      expect: () => <AuthState>[],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthAuthenticated with refreshed user when current state is authenticated',
      build: () {
        when(() => mockGetCurrentUserUseCase()).thenAnswer(
          (_) async => const User(
            id: '1',
            email: 'ali@example.com',
            handle: 'ali',
            displayName: 'Ali Updated',
            avatarUrl: 'https://example.com/avatar.png',
          ),
        );
        return cubit;
      },
      seed: () => AuthAuthenticated(tUser),
      act: (cubit) => cubit.refreshCurrentUserSilently(),
      expect: () => [
        isA<AuthAuthenticated>()
            .having((s) => s.user.displayName, 'displayName', 'Ali Updated'),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'keeps state unchanged when refresh throws',
      build: () {
        when(() => mockGetCurrentUserUseCase()).thenThrow(Exception('boom'));
        return cubit;
      },
      seed: () => AuthAuthenticated(tUser),
      act: (cubit) => cubit.refreshCurrentUserSilently(),
      expect: () => <AuthState>[],
    );
  });
}
