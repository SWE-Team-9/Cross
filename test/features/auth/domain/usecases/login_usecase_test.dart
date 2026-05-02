import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/login_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late LoginUseCase useCase;
  late FakeUser user;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
    user = FakeUser();
  });

  test('should call repository.login with correct params and return user',
      () async {
    // Arrange
    const email = 'test@example.com';
    const password = '123456';
    const captchaToken = 'mock_captcha_token';
    const rememberMe = true;

    when(() => repository.login(
          email: email,
          password: password,
          rememberMe: rememberMe,
          captchaToken: captchaToken,
        )).thenAnswer((_) async => user);

    // Act
    final result = await useCase(
      email: email,
      password: password,
      rememberMe: rememberMe,
      captchaToken: captchaToken,
    );

    // Assert
    expect(result, same(user));
    verify(() => repository.login(
          email: email,
          password: password,
          rememberMe: rememberMe,
          captchaToken: captchaToken,
        )).called(1);
    verifyNoMoreInteractions(repository);
  });
}
