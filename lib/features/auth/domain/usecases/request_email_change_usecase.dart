import '../repositories/auth_repository.dart';

class RequestEmailChangeUseCase {
  final AuthRepository repository;

  RequestEmailChangeUseCase(this.repository);

  Future<void> call({
    required String newEmail,
    required String currentPassword,
  }) {
    return repository.requestEmailChange(
      newEmail: newEmail,
      currentPassword: currentPassword,
    );
  }
}