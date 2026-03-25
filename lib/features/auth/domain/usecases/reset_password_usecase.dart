import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<void> call({
    required String code,
    required String newPassword,
    required String newPasswordConfirm,
  }) {
    return repository.resetPassword(
      code: code,
      newPassword: newPassword,
      newPasswordConfirm: newPasswordConfirm,
    );
  }
}
