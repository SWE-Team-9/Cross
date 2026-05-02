import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<User> call({
    required String email,
    required String password,
    required bool rememberMe,
    required String captchaToken,
  }) {
    return repository.login(
      email: email,
      password: password,
      rememberMe: rememberMe,
      captchaToken: captchaToken,
    );
  }
}
