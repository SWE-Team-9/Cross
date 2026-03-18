import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/check_email_exists_usecase.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/complete_profile_usecase.dart';
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

class MockCheckEmailExistsUseCase extends Mock
    implements CheckEmailExistsUseCase {}

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockRegisterUseCase extends Mock implements RegisterUseCase {}

class MockCompleteProfileUseCase extends Mock
    implements CompleteProfileUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockIsLoggedInUseCase extends Mock implements IsLoggedInUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}

class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}

class MockSendEmailVerificationUseCase extends Mock
    implements SendEmailVerificationUseCase {}

class MockVerifyEmailUseCase extends Mock implements VerifyEmailUseCase {}

class FakeUser extends Fake implements User {}

void main() {
  late AuthCubit authCubit;
  late MockCheckEmailExistsUseCase mockCheckEmailExistsUseCase;
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockCompleteProfileUseCase mockCompleteProfileUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockIsLoggedInUseCase mockIsLoggedInUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockForgotPasswordUseCase mockForgotPasswordUseCase;
  late MockResetPasswordUseCase mockResetPasswordUseCase;
  late MockSendEmailVerificationUseCase mockSendEmailVerificationUseCase;
  late MockVerifyEmailUseCase mockVerifyEmailUseCase;

  late User testUser;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    mockCheckEmailExistsUseCase = MockCheckEmailExistsUseCase();
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockCompleteProfileUseCase = MockCompleteProfileUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockIsLoggedInUseCase = MockIsLoggedInUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockForgotPasswordUseCase = MockForgotPasswordUseCase();
    mockResetPasswordUseCase = MockResetPasswordUseCase();
    mockSendEmailVerificationUseCase = MockSendEmailVerificationUseCase();
    mockVerifyEmailUseCase = MockVerifyEmailUseCase();

    testUser = FakeUser();

    authCubit = AuthCubit(
      checkEmailExistsUseCase: mockCheckEmailExistsUseCase,
      loginUseCase: mockLoginUseCase,
      registerUseCase: mockRegisterUseCase,
      completeProfileUseCase: mockCompleteProfileUseCase,
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
    await authCubit.close();
  });

  test('initial state is AuthInitial', () {
    expect(authCubit.state, isA<AuthInitial>());
  });

  group('checkAuthStatus', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when user is not logged in',
      build: () {
        when(() => mockIsLoggedInUseCase()).thenAnswer((_) async => false);
        return authCubit;
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
      verify: (_) {
        verify(() => mockIsLoggedInUseCase()).called(1);
        verifyNever(() => mockGetCurrentUserUseCase());
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when logged in but current user is null',
      build: () {
        when(() => mockIsLoggedInUseCase()).thenAnswer((_) async => true);
        when(() => mockGetCurrentUserUseCase()).thenAnswer((_) async => null);
        return authCubit;
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
      verify: (_) {
        verify(() => mockIsLoggedInUseCase()).called(1);
        verify(() => mockGetCurrentUserUseCase()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when user is logged in and current user exists',
      build: () {
        when(() => mockIsLoggedInUseCase()).thenAnswer((_) async => true);
        when(() => mockGetCurrentUserUseCase())
            .thenAnswer((_) async => testUser);
        return authCubit;
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>()
            .having((state) => state.user, 'user', same(testUser)),
      ],
      verify: (_) {
        verify(() => mockIsLoggedInUseCase()).called(1);
        verify(() => mockGetCurrentUserUseCase()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when exception happens',
      build: () {
        when(() => mockIsLoggedInUseCase()).thenThrow(Exception('failed'));
        return authCubit;
      },
      act: (cubit) => cubit.checkAuthStatus(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );
  });

  group('checkEmail', () {
    const email = 'test@example.com';

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthEmailCheckSuccess] when email check succeeds',
      build: () {
        when(() => mockCheckEmailExistsUseCase(email: email))
            .thenAnswer((_) async => true);
        return authCubit;
      },
      act: (cubit) => cubit.checkEmail(email: email),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthEmailCheckSuccess>()
            .having((state) => state.exists, 'exists', true)
            .having((state) => state.email, 'email', email),
      ],
      verify: (_) {
        verify(() => mockCheckEmailExistsUseCase(email: email)).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when email check fails',
      build: () {
        when(() => mockCheckEmailExistsUseCase(email: email))
            .thenThrow(Exception('email check failed'));
        return authCubit;
      },
      act: (cubit) => cubit.checkEmail(email: email),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((state) => state.message, 'message',
            'An unexpected error occurred.'),
      ],
    );
  });

  group('login', () {
    const email = 'test@example.com';
    const password = 'password123';

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () {
        when(() => mockLoginUseCase(email: email, password: password))
            .thenAnswer((_) async => testUser);
        return authCubit;
      },
      act: (cubit) => cubit.login(email: email, password: password),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>()
            .having((state) => state.user, 'user', same(testUser)),
      ],
      verify: (_) {
        verify(() => mockLoginUseCase(email: email, password: password))
            .called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(() => mockLoginUseCase(email: email, password: password))
            .thenThrow(Exception('login failed'));
        return authCubit;
      },
      act: (cubit) => cubit.login(email: email, password: password),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((state) => state.message, 'message',
            'An unexpected error occurred.'),
      ],
    );
  });

  group('register', () {
    const email = 'new@example.com';
    const password = 'password123';

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthRegisterSuccess] when register succeeds',
      build: () {
        when(() => mockRegisterUseCase(email: email, password: password))
            .thenAnswer((_) async => testUser);
        return authCubit;
      },
      act: (cubit) => cubit.register(email: email, password: password),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthRegisterSuccess>()
            .having((state) => state.user, 'user', same(testUser)),
      ],
      verify: (_) {
        verify(() => mockRegisterUseCase(email: email, password: password))
            .called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when register fails',
      build: () {
        when(() => mockRegisterUseCase(email: email, password: password))
            .thenThrow(Exception('register failed'));
        return authCubit;
      },
      act: (cubit) => cubit.register(email: email, password: password),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((state) => state.message, 'message',
            'An unexpected error occurred.'),
      ],
    );
  });

  group('sendEmailVerification', () {
    const email = 'verify@example.com';

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthVerificationEmailSent] when sending verification succeeds',
      build: () {
        when(() => mockSendEmailVerificationUseCase(email: email))
            .thenAnswer((_) async {});
        return authCubit;
      },
      act: (cubit) => cubit.sendEmailVerification(email: email),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthVerificationEmailSent>()
            .having((state) => state.email, 'email', email),
      ],
      verify: (_) {
        verify(() => mockSendEmailVerificationUseCase(email: email)).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when sending verification fails',
      build: () {
        when(() => mockSendEmailVerificationUseCase(email: email))
            .thenThrow(Exception('send verification failed'));
        return authCubit;
      },
      act: (cubit) => cubit.sendEmailVerification(email: email),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((state) => state.message, 'message',
            'An unexpected error occurred.'),
      ],
    );
  });

  group('verifyEmail', () {
    const email = 'verify@example.com';
    const code = '123456';

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthEmailVerified] when verification succeeds',
      build: () {
        when(() => mockVerifyEmailUseCase(email: email, code: code))
            .thenAnswer((_) async {});
        return authCubit;
      },
      act: (cubit) => cubit.verifyEmail(email: email, code: code),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthEmailVerified>(),
      ],
      verify: (_) {
        verify(() => mockVerifyEmailUseCase(email: email, code: code))
            .called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when verification fails',
      build: () {
        when(() => mockVerifyEmailUseCase(email: email, code: code))
            .thenThrow(Exception('verify email failed'));
        return authCubit;
      },
      act: (cubit) => cubit.verifyEmail(email: email, code: code),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((state) => state.message, 'message',
            'An unexpected error occurred.'),
      ],
    );
  });

  group('forgotPassword', () {
    const email = 'forgot@example.com';

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthForgotPasswordSuccess] when forgot password succeeds',
      build: () {
        when(() => mockForgotPasswordUseCase(email: email))
            .thenAnswer((_) async {});
        return authCubit;
      },
      act: (cubit) => cubit.forgotPassword(email: email),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthForgotPasswordSuccess>()
            .having((state) => state.email, 'email', email),
      ],
      verify: (_) {
        verify(() => mockForgotPasswordUseCase(email: email)).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when forgot password fails',
      build: () {
        when(() => mockForgotPasswordUseCase(email: email))
            .thenThrow(Exception('forgot password failed'));
        return authCubit;
      },
      act: (cubit) => cubit.forgotPassword(email: email),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((state) => state.message, 'message',
            'An unexpected error occurred.'),
      ],
    );
  });

  group('resetPassword', () {
    const email = 'reset@example.com';
    const code = '123456';
    const newPassword = 'newPassword123';

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthResetPasswordSuccess] when reset password succeeds',
      build: () {
        when(() => mockResetPasswordUseCase(
              email: email,
              code: code,
              newPassword: newPassword,
            )).thenAnswer((_) async {});
        return authCubit;
      },
      act: (cubit) => cubit.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthResetPasswordSuccess>(),
      ],
      verify: (_) {
        verify(() => mockResetPasswordUseCase(
              email: email,
              code: code,
              newPassword: newPassword,
            )).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when reset password fails',
      build: () {
        when(() => mockResetPasswordUseCase(
              email: email,
              code: code,
              newPassword: newPassword,
            )).thenThrow(Exception('reset password failed'));
        return authCubit;
      },
      act: (cubit) => cubit.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((state) => state.message, 'message',
            'An unexpected error occurred.'),
      ],
    );
  });

  group('completeProfile', () {
    const displayName = 'Muslim';
    const birthMonth = 5;
    const birthDay = 15;
    const birthYear = 2000;
    const gender = 'male';

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthProfileCompleted, AuthAuthenticated] when complete profile succeeds',
      build: () {
        when(() => mockCompleteProfileUseCase(
              displayName: displayName,
              birthMonth: birthMonth,
              birthDay: birthDay,
              birthYear: birthYear,
              gender: gender,
            )).thenAnswer((_) async => testUser);
        return authCubit;
      },
      act: (cubit) => cubit.completeProfile(
        displayName: displayName,
        birthMonth: birthMonth,
        birthDay: birthDay,
        birthYear: birthYear,
        gender: gender,
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthProfileCompleted>()
            .having((state) => state.user, 'user', same(testUser)),
        isA<AuthAuthenticated>()
            .having((state) => state.user, 'user', same(testUser)),
      ],
      verify: (_) {
        verify(() => mockCompleteProfileUseCase(
              displayName: displayName,
              birthMonth: birthMonth,
              birthDay: birthDay,
              birthYear: birthYear,
              gender: gender,
            )).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when complete profile fails',
      build: () {
        when(() => mockCompleteProfileUseCase(
              displayName: displayName,
              birthMonth: birthMonth,
              birthDay: birthDay,
              birthYear: birthYear,
              gender: gender,
            )).thenThrow(Exception('complete profile failed'));
        return authCubit;
      },
      act: (cubit) => cubit.completeProfile(
        displayName: displayName,
        birthMonth: birthMonth,
        birthDay: birthDay,
        birthYear: birthYear,
        gender: gender,
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((state) => state.message, 'message',
            'An unexpected error occurred.'),
      ],
    );
  });

  group('logout', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when logout succeeds',
      build: () {
        when(() => mockLogoutUseCase()).thenAnswer((_) async {});
        return authCubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
      verify: (_) {
        verify(() => mockLogoutUseCase()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when logout fails',
      build: () {
        when(() => mockLogoutUseCase()).thenThrow(Exception('logout failed'));
        return authCubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((state) => state.message, 'message',
            'An unexpected error occurred.'),
      ],
    );
  });
}
