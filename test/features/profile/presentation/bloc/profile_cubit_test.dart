import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_state.dart';
import '../../helpers/profile_test_fixtures.dart';

// Mock classes (no code generation!)
class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late ProfileCubit cubit;
  late MockGetProfileUseCase mockGetProfileUseCase;
  late MockUpdateProfileUseCase mockUpdateProfileUseCase;
  late MockProfileRepository mockProfileRepository;

  setUp(() {
    mockGetProfileUseCase = MockGetProfileUseCase();
    mockUpdateProfileUseCase = MockUpdateProfileUseCase();
    mockProfileRepository = MockProfileRepository();
    cubit = ProfileCubit(
      getProfileUseCase: mockGetProfileUseCase,
      updateProfileUseCase: mockUpdateProfileUseCase,
      profileRepository: mockProfileRepository,
    );
  });

  tearDown(() => cubit.close());

  test('initial state is ProfileInitial', () {
    expect(cubit.state, isA<ProfileInitial>());
  });

  group('loadProfile', () {
    const tHandle = 'ahmed-hassan-beats';

    blocTest<ProfileCubit, ProfileState>(
      'emits [ProfileLoading, ProfileLoaded] on success',
      build: () {
        when(() => mockGetProfileUseCase(tHandle))
            .thenAnswer((_) async => tProfileEntity);
        return cubit;
      },
      act: (c) => c.loadProfile(tHandle),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>(),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'ProfileLoaded contains the returned profile entity',
      build: () {
        when(() => mockGetProfileUseCase(tHandle))
            .thenAnswer((_) async => tProfileEntity);
        return cubit;
      },
      act: (c) => c.loadProfile(tHandle),
      expect: () => [
        isA<ProfileLoading>(),
        predicate<ProfileState>(
          (s) => s is ProfileLoaded && s.profile == tProfileEntity,
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits [ProfileLoading, ProfileError] on NotFoundFailure',
      build: () {
        when(() => mockGetProfileUseCase(tHandle))
            .thenThrow(const NotFoundFailure('This profile does not exist.'));
        return cubit;
      },
      act: (c) => c.loadProfile(tHandle),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileError>(),
      ],
    );
  });

  group('updateProfile', () {
    const tParams = UpdateProfileParams(
      displayName: 'Ahmed Official',
      bio: 'New EP dropping soon',
    );

    blocTest<ProfileCubit, ProfileState>(
      'allows updateProfile retry from ProfileUpdateError state',
      build: () {
        when(() => mockUpdateProfileUseCase(tParams))
            .thenAnswer((_) async => tProfileEntity);
        return cubit;
      },
      seed: () => ProfileUpdateError(tProfileEntity, 'Previous failure'),
      act: (c) => c.updateProfile(tParams),
      expect: () => [
        isA<ProfileUpdating>(),
        isA<ProfileUpdateSuccess>(),
        isA<ProfileLoaded>(),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits updating, success, then loaded with updated profile on success',
      build: () {
        when(() => mockUpdateProfileUseCase(tParams))
            .thenAnswer((_) async => tProfileEntity);
        return cubit;
      },
      seed: () => ProfileLoaded(tProfileEntity),
      act: (c) => c.updateProfile(tParams),
      expect: () => [
        isA<ProfileUpdating>(),
        isA<ProfileUpdateSuccess>(),
        predicate<ProfileState>(
          (s) => s is ProfileLoaded && s.profile == tProfileEntity,
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits nothing when state is not ProfileLoaded (guard condition)',
      build: () => cubit,
      act: (c) => c.updateProfile(tParams),
      expect: () => [],
    );
  });

  group('uploadImage', () {
    const tAvatarUrl = 'https://s3.aws.com/new-avatar.jpg';
    const tFilePath = '/local/path/image.jpg';

    blocTest<ProfileCubit, ProfileState>(
      'emits [ProfileImageUploading, ProfileLoaded] on avatar upload success',
      build: () {
        when(() => mockProfileRepository.uploadProfileImage(
              imageType: ProfileImageType.AVATAR,
              filePath: tFilePath,
            )).thenAnswer((_) async => tAvatarUrl);
        return cubit;
      },
      seed: () => ProfileLoaded(tProfileEntity),
      act: (c) => c.uploadImage(
        imageType: ProfileImageType.AVATAR,
        filePath: tFilePath,
      ),
      expect: () => [
        isA<ProfileImageUploading>(),
        isA<ProfileLoaded>(),
      ],
    );
  });
}
