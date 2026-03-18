import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/reset_password_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late ResetPasswordUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = ResetPasswordUseCase(repository);
  });

  test('should call repository.resetPassword', () async {
    const email = 'test@example.com';
    const code = '123456';
    const newPassword = 'newPass123';

    when(() => repository.resetPassword(
          email: email,
          code: code,
          newPassword: newPassword,
        )).thenAnswer((_) async {});

    await useCase(
      email: email,
      code: code,
      newPassword: newPassword,
    );

    verify(() => repository.resetPassword(
          email: email,
          code: code,
          newPassword: newPassword,
        )).called(1);
    verifyNoMoreInteractions(repository);
  });
}
