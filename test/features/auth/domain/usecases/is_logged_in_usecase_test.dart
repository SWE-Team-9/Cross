import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/is_logged_in_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late IsLoggedInUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = IsLoggedInUseCase(repository);
  });

  test('should call repository.isLoggedIn and return result', () async {
    when(() => repository.isLoggedIn()).thenAnswer((_) async => true);

    final result = await useCase();

    expect(result, true);
    verify(() => repository.isLoggedIn()).called(1);
    verifyNoMoreInteractions(repository);
  });
}