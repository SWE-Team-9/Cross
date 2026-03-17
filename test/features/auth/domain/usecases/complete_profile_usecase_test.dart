import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/usecases/complete_profile_usecase.dart';

import '../../helpers/auth_test_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late CompleteProfileUseCase useCase;
  late FakeUser user;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    repository = MockAuthRepository();
    useCase = CompleteProfileUseCase(repository);
    user = FakeUser();
  });

  test('should call repository.completeProfile and return user', () async {
    const displayName = 'Muslim';
    const birthMonth = 5;
    const birthDay = 15;
    const birthYear = 2000;
    const gender = 'male';

    when(() => repository.completeProfile(
          displayName: displayName,
          birthMonth: birthMonth,
          birthDay: birthDay,
          birthYear: birthYear,
          gender: gender,
        )).thenAnswer((_) async => user);

    final result = await useCase(
      displayName: displayName,
      birthMonth: birthMonth,
      birthDay: birthDay,
      birthYear: birthYear,
      gender: gender,
    );

    expect(result, same(user));
    verify(() => repository.completeProfile(
          displayName: displayName,
          birthMonth: birthMonth,
          birthDay: birthDay,
          birthYear: birthYear,
          gender: gender,
        )).called(1);
    verifyNoMoreInteractions(repository);
  });
}