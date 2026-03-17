import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/forgot_password_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late ForgotPasswordUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = ForgotPasswordUseCase(repository);
  });

  test('should call repository.forgotPassword', () async {
    const email = 'forgot@example.com';

    when(() => repository.forgotPassword(email: email))
        .thenAnswer((_) async {});

    await useCase(email: email);

    verify(() => repository.forgotPassword(email: email)).called(1);
    verifyNoMoreInteractions(repository);
  });
}