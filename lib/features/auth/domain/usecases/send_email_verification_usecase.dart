import '../repositories/auth_repository.dart';

class SendEmailVerificationUseCase {
  final AuthRepository repository;

  SendEmailVerificationUseCase(this.repository);

  Future<void> call({
    required String email,
  }) {
    return repository.sendEmailVerification(email: email);
  }
}
