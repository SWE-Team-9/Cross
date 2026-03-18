import '../repositories/auth_repository.dart';

class CheckEmailExistsUseCase {
  final AuthRepository repository;

  CheckEmailExistsUseCase(this.repository);

  Future<bool> call({
    required String email,
  }) {
    return repository.checkEmailExists(email: email);
  }
}
