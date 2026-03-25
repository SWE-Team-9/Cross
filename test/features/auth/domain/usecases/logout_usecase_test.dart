import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/logout_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late LogoutUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LogoutUseCase(repository);
  });

  test('should call repository.logout', () async {
    when(() => repository.logout()).thenAnswer((_) async {});

    await useCase();

    verify(() => repository.logout()).called(1);
    verifyNoMoreInteractions(repository);
  });
}
