import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/profile_entity.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/update_profile_usecase.dart';
import '../../helpers/profile_test_fixtures.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late UpdateProfileUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = UpdateProfileUseCase(mockRepository);
  });

  group('UpdateProfileUseCase', () {
    group('call', () {
      test('passes all provided fields to the repository', () async {
        const params = UpdateProfileParams(
          displayName: 'Ahmed Official',
          bio: 'New EP dropping soon',
          location: 'Alexandria, Egypt',
          favoriteGenres: ['Lo-Fi', 'Oriental'],
          visibility: ProfileVisibility.PRIVATE,
        );

        when(() => mockRepository.updateProfile(
              displayName: 'Ahmed Official',
              bio: 'New EP dropping soon',
              location: 'Alexandria, Egypt',
              favoriteGenres: ['Lo-Fi', 'Oriental'],
              visibility: ProfileVisibility.PRIVATE,
            )).thenAnswer((_) async => tProfileEntity);

        final result = await useCase(params);

        expect(result, tProfileEntity);
        verify(() => mockRepository.updateProfile(
              displayName: 'Ahmed Official',
              bio: 'New EP dropping soon',
              location: 'Alexandria, Egypt',
              favoriteGenres: ['Lo-Fi', 'Oriental'],
              visibility: ProfileVisibility.PRIVATE,
            )).called(1);
      });

      test('passes only displayName when only displayName is in params',
          () async {
        const params = UpdateProfileParams(displayName: 'Ahmed Official');
        when(() => mockRepository.updateProfile(
              displayName: 'Ahmed Official',
              bio: null,
              location: null,
              favoriteGenres: null,
              visibility: null,
            )).thenAnswer((_) async => tProfileEntity);

        await useCase(params);

        verify(() => mockRepository.updateProfile(
              displayName: 'Ahmed Official',
              bio: null,
              location: null,
              favoriteGenres: null,
              visibility: null,
            )).called(1);
      });

      test('throws ValidationFailure when repository throws ValidationFailure',
          () async {
        const params = UpdateProfileParams(displayName: 'x');
        when(() => mockRepository.updateProfile(displayName: 'x')).thenThrow(
          const ValidationFailure('Name must be at least 2 characters.'),
        );

        expect(
          () async => await useCase(params),
          throwsA(isA<ValidationFailure>()),
        );
      });
    });
  });
}
