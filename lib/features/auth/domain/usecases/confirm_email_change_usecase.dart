import '../repositories/auth_repository.dart';

class ConfirmEmailChangeUseCase {
  final AuthRepository repository;

  ConfirmEmailChangeUseCase(this.repository);

  Future<void> call({
    required String token,
  }) {
    return repository.confirmEmailChange(token: token);
  }
}