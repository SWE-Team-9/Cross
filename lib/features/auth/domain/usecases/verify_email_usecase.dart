import '../repositories/auth_repository.dart';

class VerifyEmailUseCase {
  final AuthRepository repository;

  VerifyEmailUseCase(this.repository);

  Future<void> call({
    required String email,
    required String code,
  }) {
    return repository.verifyEmail(
      email: email,
      code: code,
    );
  }
}
