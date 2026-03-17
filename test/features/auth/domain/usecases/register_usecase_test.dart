import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/register_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late RegisterUseCase useCase;
  late FakeUser user;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    repository = MockAuthRepository();
    useCase = RegisterUseCase(repository);
    user = FakeUser();
  });

  test('should call repository.register and return user', () async {
    const email = 'new@example.com';
    const password = '123456';

    when(() => repository.register(email: email, password: password))
        .thenAnswer((_) async => user);

    final result = await useCase(email: email, password: password);

    expect(result, same(user));
    verify(() => repository.register(email: email, password: password))
        .called(1);
    verifyNoMoreInteractions(repository);
  });
}