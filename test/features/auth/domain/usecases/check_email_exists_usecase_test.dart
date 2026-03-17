import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/check_email_exists_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late CheckEmailExistsUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = CheckEmailExistsUseCase(repository);
  });

  test('should call repository.checkEmailExists and return result', () async {
    const email = 'test@example.com';

    when(() => repository.checkEmailExists(email: email))
        .thenAnswer((_) async => true);

    final result = await useCase(email: email);

    expect(result, true);
    verify(() => repository.checkEmailExists(email: email)).called(1);
    verifyNoMoreInteractions(repository);
  });
}