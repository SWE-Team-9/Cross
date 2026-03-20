import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<User> call({
    required String email,
    required String password,
    required String passwordConfirm,
    required String displayName,
    required String dateOfBirth,
    required String gender,    
  }) {
    return repository.register(
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
      displayName: displayName,
      dateOfBirth: dateOfBirth,
      gender: gender,
    );
  }
}