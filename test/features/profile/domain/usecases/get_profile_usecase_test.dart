import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/get_profile_usecase.dart';
import '../../helpers/profile_test_fixtures.dart';

// Create mock class (no code generation needed!)
class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late GetProfileUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = GetProfileUseCase(mockRepository);
  });

  group('GetProfileUseCase', () {
    const tHandle = 'ahmed-hassan-beats';

    test('returns ProfileEntity from repository when successful', () async {
      when(() => mockRepository.getProfile(tHandle))
          .thenAnswer((_) async => tProfileEntity);

      final result = await useCase(tHandle);

      expect(result, tProfileEntity);
      verify(() => mockRepository.getProfile(tHandle)).called(1);
    });

    test('passes the handle to the repository without modification', () async {
      when(() => mockRepository.getProfile(tHandle))
          .thenAnswer((_) async => tProfileEntity);

      await useCase(tHandle);

      verify(() => mockRepository.getProfile(tHandle)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('throws NotFoundFailure when repository throws NotFoundFailure', () async {
      when(() => mockRepository.getProfile(tHandle))
          .thenThrow(const NotFoundFailure('This profile does not exist.'));

      expect(
        () async => await useCase(tHandle),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('throws AuthFailure when repository throws AuthFailure', () async {
      when(() => mockRepository.getProfile(tHandle))
          .thenThrow(const AuthFailure('You do not have permission.'));

      expect(
        () async => await useCase(tHandle),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('throws ServerFailure when repository throws ServerFailure', () async {
      when(() => mockRepository.getProfile(tHandle))
          .thenThrow(const ServerFailure('Something went wrong.'));

      expect(
        () async => await useCase(tHandle),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}