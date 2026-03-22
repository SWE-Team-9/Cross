import '../repositories/auth_repository.dart';

class VerifyEmailUseCase {
  final AuthRepository repository;

  VerifyEmailUseCase(this.repository);

  Future<void> call({
    required String code,
  }) {
    return repository.verifyEmail(
      email: '',
      code: code,
    );
  }
}
