import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CompleteProfileUseCase {
  final AuthRepository repository;

  CompleteProfileUseCase(this.repository);

  Future<User> call({
    required String displayName,
    required int birthMonth,
    required int birthDay,
    required int birthYear,
    required String gender,
  }) {
    return repository.completeProfile(
      displayName: displayName,
      birthMonth: birthMonth,
      birthDay: birthDay,
      birthYear: birthYear,
      gender: gender,
    );
  }
}