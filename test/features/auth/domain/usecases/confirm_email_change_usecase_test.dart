import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/confirm_email_change_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late ConfirmEmailChangeUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = ConfirmEmailChangeUseCase(repository);
  });

  test('calls repository.confirmEmailChange with provided token', () async {
    const token = 'tkn-123';

    when(() => repository.confirmEmailChange(token: token))
        .thenAnswer((_) async {});

    await useCase(token: token);

    verify(() => repository.confirmEmailChange(token: token)).called(1);
    verifyNoMoreInteractions(repository);
  });
}
