import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/register_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late RegisterUseCase useCase;
  late FakeUser user;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    repository = MockAuthRepository();
    useCase = RegisterUseCase(repository);
    user = FakeUser();
  });

  test(
      'should call repository.register with all required parameters and return user',
      () async {
    // Arrange
    const email = 'new@example.com';
    const password = 'password123';
    const passwordConfirm = 'password123';
    const displayName = 'New User';
    const dateOfBirth = '2000-01-01';
    const gender = 'MALE';
    const captchaToken = 'mock_captcha_token';

    when(() => repository.register(
          email: email,
          password: password,
          passwordConfirm: passwordConfirm,
          displayName: displayName,
          dateOfBirth: dateOfBirth,
          gender: gender,
          captchaToken: captchaToken,
        )).thenAnswer((_) async => user);

    // Act
    final result = await useCase(
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
      displayName: displayName,
      dateOfBirth: dateOfBirth,
      gender: gender,
      captchaToken: captchaToken,
    );

    // Assert
    expect(result, same(user));
    verify(() => repository.register(
          email: email,
          password: password,
          passwordConfirm: passwordConfirm,
          displayName: displayName,
          dateOfBirth: dateOfBirth,
          gender: gender,
          captchaToken: captchaToken,
        )).called(1);
    verifyNoMoreInteractions(repository);
  });
}
