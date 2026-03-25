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

  test('should call repository.resetPassword with correct parameters',
      () async {
    // Arrange
    const tCode = '123456';
    const tNewPassword = 'newPass123';
    const tNewPasswordConfirm = 'newPass123';

    when(() => repository.resetPassword(
          code: tCode,
          newPassword: tNewPassword,
          newPasswordConfirm: tNewPasswordConfirm,
        )).thenAnswer((_) async => {});

    // Act
    await useCase(
      code: tCode,
      newPassword: tNewPassword,
      newPasswordConfirm: tNewPasswordConfirm,
    );

    // Assert
    verify(() => repository.resetPassword(
          code: tCode,
          newPassword: tNewPassword,
          newPasswordConfirm: tNewPasswordConfirm,
        )).called(1);
    verifyNoMoreInteractions(repository);
  });
}
