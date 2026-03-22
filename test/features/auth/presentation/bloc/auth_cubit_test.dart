import 'package:bloc_test/bloc_test.dart';
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

// Mocks
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

class FakeUser extends Fake implements User {}

void main() {
  late AuthCubit authCubit;
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
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
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockIsLoggedInUseCase = MockIsLoggedInUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockForgotPasswordUseCase = MockForgotPasswordUseCase();
    mockResetPasswordUseCase = MockResetPasswordUseCase();
    mockSendEmailVerificationUseCase = MockSendEmailVerificationUseCase();
    mockVerifyEmailUseCase = MockVerifyEmailUseCase();

    testUser = FakeUser();

    authCubit = AuthCubit(
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
    await authCubit.close();
  });

  test('initial state is AuthInitial', () {
    expect(authCubit.state, isA<AuthInitial>());
  });

  group('login', () {
    const email = 'test@example.com';
    const password = 'password123';
    const captcha = 'token';

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login succeeds',
      build: () {
        when(() => mockLoginUseCase(
              email: email,
              password: password,
              captchaToken: captcha,
            )).thenAnswer((_) async => testUser);
        return authCubit;
      },
      act: (cubit) =>
          cubit.login(email: email, password: password, captchaToken: captcha),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having((s) => s.user, 'user', testUser),
      ],
    );
  });

  group('register', () {
    const email = 'new@example.com';
    const password = 'password123';
    const captcha = 'token';

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthRegisterSuccess] when registration succeeds',
      build: () {
        when(() => mockRegisterUseCase(
              email: email,
              password: password,
              passwordConfirm: password,
              displayName: 'Test',
              dateOfBirth: '2000-01-01',
              gender: 'MALE',
              captchaToken: captcha,
            )).thenAnswer((_) async => testUser);
        return authCubit;
      },
      act: (cubit) => cubit.register(
        email: email,
        password: password,
        passwordConfirm: password,
        displayName: 'Test',
        dateOfBirth: '2000-01-01',
        gender: 'MALE',
        captchaToken: captcha,
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthRegisterSuccess>().having((s) => s.user, 'user', testUser),
      ],
    );
  });

  group('sendEmailVerification', () {
    const email = 'verify@example.com';

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthVerificationEmailSent] when succeeds',
      build: () {
        when(() => mockSendEmailVerificationUseCase(email: email))
            .thenAnswer((_) async => {});
        return authCubit;
      },
      act: (cubit) => cubit.sendEmailVerification(email: email),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthVerificationEmailSent>().having((s) => s.email, 'email', email),
      ],
    );

    // اختبار قيد الـ 60 ثانية (الذي أضفناه مؤخراً)
    blocTest<AuthCubit, AuthState>(
      'does not emit new states if called again within cooldown',
      build: () {
        when(() => mockSendEmailVerificationUseCase(email: email))
            .thenAnswer((_) async => {});
        return authCubit;
      },
      act: (cubit) async {
        await cubit.sendEmailVerification(email: email); // First call
        await cubit.sendEmailVerification(email: email); // Should be ignored
      },
      skip: 2, // تخطي حالات النداء الأول
      expect: () => [], // لا يتوقع انبعاث أي حالة جديدة للنداء الثاني
    );
  });

  group('logout', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] on success',
      build: () {
        when(() => mockLogoutUseCase()).thenAnswer((_) async => {});
        return authCubit;
      },
      act: (cubit) => cubit.logout(),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
    );
  });
}
