import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/login_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late LoginUseCase useCase;
  late FakeUser user;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
    user = FakeUser();
  });

  test('should call repository.login and return user', () async {
    const email = 'test@example.com';
    const password = '123456';

    when(() => repository.login(email: email, password: password))
        .thenAnswer((_) async => user);

    final result = await useCase(email: email, password: password);

    expect(result, same(user));
    verify(() => repository.login(email: email, password: password)).called(1);
    verifyNoMoreInteractions(repository);
  });
}