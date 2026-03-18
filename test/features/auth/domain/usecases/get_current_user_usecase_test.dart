import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/get_current_user_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late GetCurrentUserUseCase useCase;
  late FakeUser user;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    repository = MockAuthRepository();
    useCase = GetCurrentUserUseCase(repository);
    user = FakeUser();
  });

  test('should call repository.getCurrentUser and return user', () async {
    when(() => repository.getCurrentUser()).thenAnswer((_) async => user);

    final result = await useCase();

    expect(result, same(user));
    verify(() => repository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('should return null when repository returns null', () async {
    when(() => repository.getCurrentUser()).thenAnswer((_) async => null);

    final result = await useCase();

    expect(result, isNull);
    verify(() => repository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(repository);
  });
}
