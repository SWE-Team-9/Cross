import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/verify_email_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late VerifyEmailUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = VerifyEmailUseCase(repository);
  });

  test('should call repository.verifyEmail', () async {
    const email = 'verify@example.com';
    const code = '123456';

    when(() => repository.verifyEmail(email: email, code: code))
        .thenAnswer((_) async {});

    await useCase(email: email, code: code);

    verify(() => repository.verifyEmail(email: email, code: code)).called(1);
    verifyNoMoreInteractions(repository);
  });
}