import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/profile_entity.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_state.dart';

class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockGetProfileUseCase mockGetProfileUseCase;
  late MockUpdateProfileUseCase mockUpdateProfileUseCase;
  late MockProfileRepository mockProfileRepository;

  const profile = ProfileEntity(
    id: '1',
    displayName: 'Ali',
    handle: 'ali',
    bio: 'bio',
    location: 'Cairo, Egypt',
    avatarUrl: 'avatar-url',
    coverPhotoUrl: 'cover-url',
    accountTier: AccountTier.LISTENER,
    favoriteGenres: ['Rock'],
    externalLinks: {'x': 'y'},
    visibility: ProfileVisibility.PUBLIC,
    followersCount: 10,
    followingCount: 20,
  );

  const updatedProfile = ProfileEntity(
    id: '1',
    displayName: 'Ali Updated',
    handle: 'ali',
    bio: 'new bio',
    location: 'Giza, Egypt',
    avatarUrl: 'avatar-new',
    coverPhotoUrl: 'cover-new',
    accountTier: AccountTier.LISTENER,
    favoriteGenres: ['Rock'],
    externalLinks: {'x': 'y'},
    visibility: ProfileVisibility.PUBLIC,
    followersCount: 10,
    followingCount: 20,
  );

  setUpAll(() {
    registerFallbackValue(
      const UpdateProfileParams(
        displayName: 'fallback',
      ),
    );
  });

  setUp(() {
    mockGetProfileUseCase = MockGetProfileUseCase();
    mockUpdateProfileUseCase = MockUpdateProfileUseCase();
    mockProfileRepository = MockProfileRepository();
  });

  ProfileCubit buildCubit() {
    return ProfileCubit(
      getProfileUseCase: mockGetProfileUseCase,
      updateProfileUseCase: mockUpdateProfileUseCase,
      profileRepository: mockProfileRepository,
    );
  }

  test('initial state is ProfileInitial', () {
    expect(buildCubit().state, isA<ProfileInitial>());
  });

  blocTest<ProfileCubit, ProfileState>(
    'loadProfile emits [ProfileLoading, ProfileLoaded] on success',
    build: () {
      when(() => mockGetProfileUseCase('ali'))
          .thenAnswer((_) async => profile);
      return buildCubit();
    },
    act: (cubit) => cubit.loadProfile('ali'),
    expect: () => [
      isA<ProfileLoading>(),
      isA<ProfileLoaded>()
          .having((s) => s.profile.displayName, 'displayName', 'Ali'),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'loadProfile emits [ProfileLoading, ProfileError] on Failure',
    build: () {
      when(() => mockGetProfileUseCase('ali'))
          .thenThrow(const ServerFailure('server failed'));
      return buildCubit();
    },
    act: (cubit) => cubit.loadProfile('ali'),
    expect: () => [
      isA<ProfileLoading>(),
      isA<ProfileError>().having((s) => s.message, 'message', 'server failed'),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'loadProfile emits generic error on unexpected exception',
    build: () {
      when(() => mockGetProfileUseCase('ali')).thenThrow(Exception('boom'));
      return buildCubit();
    },
    act: (cubit) => cubit.loadProfile('ali'),
    expect: () => [
      isA<ProfileLoading>(),
      isA<ProfileError>().having(
        (s) => s.message,
        'message',
        'Something went wrong. Please try again.',
      ),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateProfile emits updating then success then loaded',
    build: () {
      when(() => mockUpdateProfileUseCase(any()))
          .thenAnswer((_) async => updatedProfile);

      final cubit = buildCubit();
      cubit.emit(ProfileLoaded(profile));
      return cubit;
    },
    act: (cubit) => cubit.updateProfile(
      const UpdateProfileParams(
        displayName: 'Ali Updated',
        bio: 'new bio',
      ),
    ),
    expect: () => [
      isA<ProfileUpdating>()
          .having((s) => s.currentProfile.displayName, 'current', 'Ali'),
      isA<ProfileUpdateSuccess>().having(
        (s) => s.updatedProfile.displayName,
        'updated',
        'Ali Updated',
      ),
      isA<ProfileLoaded>()
          .having((s) => s.profile.displayName, 'loaded', 'Ali Updated'),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateProfile emits ProfileUpdateError on Failure',
    build: () {
      when(() => mockUpdateProfileUseCase(any()))
          .thenThrow(const ValidationFailure('invalid'));

      final cubit = buildCubit();
      cubit.emit(ProfileLoaded(profile));
      return cubit;
    },
    act: (cubit) => cubit.updateProfile(
      const UpdateProfileParams(displayName: 'Bad'),
    ),
    expect: () => [
      isA<ProfileUpdating>(),
      isA<ProfileUpdateError>()
          .having((s) => s.message, 'message', 'invalid'),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateProfile emits generic error on unexpected exception',
    build: () {
      when(() => mockUpdateProfileUseCase(any()))
          .thenThrow(Exception('boom'));

      final cubit = buildCubit();
      cubit.emit(ProfileLoaded(profile));
      return cubit;
    },
    act: (cubit) => cubit.updateProfile(
      const UpdateProfileParams(displayName: 'Bad'),
    ),
    expect: () => [
      isA<ProfileUpdating>(),
      isA<ProfileUpdateError>().having(
        (s) => s.message,
        'message',
        'Unable to update profile. Please try again.',
      ),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateProfile does nothing when there is no current profile state',
    build: buildCubit,
    act: (cubit) => cubit.updateProfile(
      const UpdateProfileParams(displayName: 'Ali'),
    ),
    expect: () => [],
  );

  blocTest<ProfileCubit, ProfileState>(
    'uploadImage emits uploading then loaded with updated avatar',
    build: () {
      when(
        () => mockProfileRepository.uploadProfileImage(
          imageType: ProfileImageType.AVATAR,
          filePath: '/tmp/a.png',
        ),
      ).thenAnswer((_) async => 'avatar-updated');

      final cubit = buildCubit();
      cubit.emit(ProfileLoaded(profile));
      return cubit;
    },
    act: (cubit) => cubit.uploadImage(
      imageType: ProfileImageType.AVATAR,
      filePath: '/tmp/a.png',
    ),
    expect: () => [
      isA<ProfileImageUploading>()
          .having((s) => s.imageType, 'imageType', ProfileImageType.AVATAR),
      isA<ProfileLoaded>()
          .having((s) => s.profile.avatarUrl, 'avatarUrl', 'avatar-updated'),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'uploadImage emits uploading then loaded with updated cover',
    build: () {
      when(
        () => mockProfileRepository.uploadProfileImage(
          imageType: ProfileImageType.COVER,
          filePath: '/tmp/c.png',
        ),
      ).thenAnswer((_) async => 'cover-updated');

      final cubit = buildCubit();
      cubit.emit(ProfileLoaded(profile));
      return cubit;
    },
    act: (cubit) => cubit.uploadImage(
      imageType: ProfileImageType.COVER,
      filePath: '/tmp/c.png',
    ),
    expect: () => [
      isA<ProfileImageUploading>()
          .having((s) => s.imageType, 'imageType', ProfileImageType.COVER),
      isA<ProfileLoaded>().having(
        (s) => s.profile.coverPhotoUrl,
        'coverPhotoUrl',
        'cover-updated',
      ),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'uploadImage emits ProfileUpdateError on Failure',
    build: () {
      when(
        () => mockProfileRepository.uploadProfileImage(
          imageType: ProfileImageType.AVATAR,
          filePath: '/tmp/a.png',
        ),
      ).thenThrow(const ServerFailure('upload failed'));

      final cubit = buildCubit();
      cubit.emit(ProfileLoaded(profile));
      return cubit;
    },
    act: (cubit) => cubit.uploadImage(
      imageType: ProfileImageType.AVATAR,
      filePath: '/tmp/a.png',
    ),
    expect: () => [
      isA<ProfileImageUploading>(),
      isA<ProfileUpdateError>()
          .having((s) => s.message, 'message', 'upload failed'),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'uploadImage emits generic error on unexpected exception',
    build: () {
      when(
        () => mockProfileRepository.uploadProfileImage(
          imageType: ProfileImageType.AVATAR,
          filePath: '/tmp/a.png',
        ),
      ).thenThrow(Exception('boom'));

      final cubit = buildCubit();
      cubit.emit(ProfileLoaded(profile));
      return cubit;
    },
    act: (cubit) => cubit.uploadImage(
      imageType: ProfileImageType.AVATAR,
      filePath: '/tmp/a.png',
    ),
    expect: () => [
      isA<ProfileImageUploading>(),
      isA<ProfileUpdateError>().having(
        (s) => s.message,
        'message',
        'Unable to upload image. Please try again.',
      ),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'uploadImage does nothing when there is no current profile state',
    build: buildCubit,
    act: (cubit) => cubit.uploadImage(
      imageType: ProfileImageType.AVATAR,
      filePath: '/tmp/a.png',
    ),
    expect: () => [],
  );
}