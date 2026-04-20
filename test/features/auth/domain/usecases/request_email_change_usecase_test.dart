import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/request_email_change_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late RequestEmailChangeUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = RequestEmailChangeUseCase(repository);
  });

  test('calls repository.requestEmailChange with expected params', () async {
    const email = 'new@example.com';
    const password = 'pass123';

    when(
      () => repository.requestEmailChange(
        newEmail: email,
        currentPassword: password,
      ),
    ).thenAnswer((_) async {});

    await useCase(
      newEmail: email,
      currentPassword: password,
    );

    verify(
      () => repository.requestEmailChange(
        newEmail: email,
        currentPassword: password,
      ),
    ).called(1);
    verifyNoMoreInteractions(repository);
  });
}
