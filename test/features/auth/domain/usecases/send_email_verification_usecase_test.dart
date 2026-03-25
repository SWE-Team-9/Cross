import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/send_email_verification_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late SendEmailVerificationUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = SendEmailVerificationUseCase(repository);
  });

  test('should call repository.sendEmailVerification', () async {
    const email = 'verify@example.com';

    when(() => repository.sendEmailVerification(email: email))
        .thenAnswer((_) async {});

    await useCase(email: email);

    verify(() => repository.sendEmailVerification(email: email)).called(1);
    verifyNoMoreInteractions(repository);
  });
}
