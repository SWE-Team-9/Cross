import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/managed_track.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';
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

  const ownTrack = ManagedTrack(
    id: 'track-1',
    title: 'Midnight Echoes',
    visibility: TrackManagementVisibility.publicTrack,
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
      when(() => mockGetProfileUseCase('ali')).thenAnswer((_) async => profile);
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
    'loadOwnProfile emits [ProfileLoading, ProfileLoaded] on success',
    build: () {
      when(() => mockProfileRepository.getMyProfile())
          .thenAnswer((_) async => profile);
      when(() => mockProfileRepository.getUserTracks('1'))
          .thenAnswer((_) async => [ownTrack]);
      return buildCubit();
    },
    act: (cubit) => cubit.loadOwnProfile(),
    expect: () => [
      isA<ProfileLoading>(),
      isA<ProfileLoaded>()
          .having((s) => s.profile.handle, 'handle', 'ali')
          .having((s) => s.tracks, 'tracks', [ownTrack]),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'loadOwnProfile emits [ProfileLoading, ProfileError] on Failure',
    build: () {
      when(() => mockProfileRepository.getMyProfile())
          .thenThrow(const ServerFailure('my profile failed'));
      return buildCubit();
    },
    act: (cubit) => cubit.loadOwnProfile(),
    expect: () => [
      isA<ProfileLoading>(),
      isA<ProfileError>()
          .having((s) => s.message, 'message', 'my profile failed'),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'loadOwnProfile emits generic error on unexpected exception',
    build: () {
      when(() => mockProfileRepository.getMyProfile())
          .thenThrow(Exception('boom'));
      return buildCubit();
    },
    act: (cubit) => cubit.loadOwnProfile(),
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
      isA<ProfileUpdateError>().having((s) => s.message, 'message', 'invalid'),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateProfile emits generic error on unexpected exception',
    build: () {
      when(() => mockUpdateProfileUseCase(any())).thenThrow(Exception('boom'));

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
    'updateProfile emits ProfileLoaded(current) when no changes are provided',
    build: () {
      final cubit = buildCubit();
      cubit.emit(ProfileLoaded(profile));
      return cubit;
    },
    act: (cubit) => cubit.updateProfile(const UpdateProfileParams()),
    expect: () => [
      isA<ProfileLoaded>()
          .having((s) => s.profile.displayName, 'displayName', 'Ali'),
    ],
    verify: (_) {
      verifyNever(() => mockUpdateProfileUseCase(any()));
      verifyNever(
        () => mockProfileRepository.updateExternalLinks(
          externalLinks: any(named: 'externalLinks'),
        ),
      );
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateProfile with only external links skips base update and emits success',
    build: () {
      when(
        () => mockProfileRepository.updateExternalLinks(
          externalLinks: {'instagram': 'https://instagram.com/user'},
        ),
      ).thenAnswer((_) async => {'instagram': 'https://instagram.com/user'});

      final cubit = buildCubit();
      cubit.emit(ProfileLoaded(profile));
      return cubit;
    },
    act: (cubit) => cubit.updateProfile(
      const UpdateProfileParams(
        externalLinks: {'instagram': 'https://instagram.com/user'},
      ),
    ),
    expect: () => [
      isA<ProfileUpdating>(),
      isA<ProfileUpdateSuccess>().having(
        (s) => s.updatedProfile.externalLinks['instagram'],
        'instagram',
        'https://instagram.com/user',
      ),
      isA<ProfileLoaded>().having(
        (s) => s.profile.externalLinks['instagram'],
        'instagramLoaded',
        'https://instagram.com/user',
      ),
    ],
    verify: (_) {
      verifyNever(() => mockUpdateProfileUseCase(any()));
      verify(
        () => mockProfileRepository.updateExternalLinks(
          externalLinks: {'instagram': 'https://instagram.com/user'},
        ),
      ).called(1);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateProfile with base and external changes calls both update paths',
    build: () {
      when(() => mockUpdateProfileUseCase(any()))
          .thenAnswer((_) async => updatedProfile);
      when(
        () => mockProfileRepository.updateExternalLinks(
          externalLinks: {'x': 'https://x.com/new'},
        ),
      ).thenAnswer((_) async => {'x': 'https://x.com/new'});

      final cubit = buildCubit();
      cubit.emit(ProfileLoaded(profile));
      return cubit;
    },
    act: (cubit) => cubit.updateProfile(
      const UpdateProfileParams(
        displayName: 'Ali Updated',
        externalLinks: {'x': 'https://x.com/new'},
      ),
    ),
    expect: () => [
      isA<ProfileUpdating>(),
      isA<ProfileUpdateSuccess>().having(
        (s) => s.updatedProfile.externalLinks['x'],
        'x',
        'https://x.com/new',
      ),
      isA<ProfileLoaded>().having(
        (s) => s.profile.externalLinks['x'],
        'xLoaded',
        'https://x.com/new',
      ),
    ],
    verify: (_) {
      verify(() => mockUpdateProfileUseCase(any())).called(1);
      verify(
        () => mockProfileRepository.updateExternalLinks(
          externalLinks: {'x': 'https://x.com/new'},
        ),
      ).called(1);
    },
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateProfile resolves current profile from ProfileUpdating state',
    build: () {
      final cubit = buildCubit();
      cubit.emit(ProfileUpdating(profile));
      return cubit;
    },
    act: (cubit) => cubit.updateProfile(const UpdateProfileParams()),
    expect: () => [
      isA<ProfileLoaded>().having((s) => s.profile.id, 'id', '1'),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateProfile resolves current profile from ProfileUpdateError state',
    build: () {
      final cubit = buildCubit();
      cubit.emit(ProfileUpdateError(profile, 'err'));
      return cubit;
    },
    act: (cubit) => cubit.updateProfile(const UpdateProfileParams()),
    expect: () => [
      isA<ProfileLoaded>().having((s) => s.profile.id, 'id', '1'),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateProfile resolves current profile from ProfileImageUploading state',
    build: () {
      final cubit = buildCubit();
      cubit.emit(ProfileImageUploading(profile, ProfileImageType.AVATAR));
      return cubit;
    },
    act: (cubit) => cubit.updateProfile(const UpdateProfileParams()),
    expect: () => [
      isA<ProfileLoaded>().having((s) => s.profile.id, 'id', '1'),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'updateProfile resolves current profile from ProfileUpdateSuccess state',
    build: () {
      final cubit = buildCubit();
      cubit.emit(ProfileUpdateSuccess(profile));
      return cubit;
    },
    act: (cubit) => cubit.updateProfile(const UpdateProfileParams()),
    expect: () => [
      isA<ProfileLoaded>().having((s) => s.profile.id, 'id', '1'),
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
    'uploadImage emits ProfileImageUploadError on Failure',
    build: () {
      when(
        () => mockProfileRepository.uploadProfileImage(
          imageType: ProfileImageType.AVATAR,
          filePath: '/tmp/a.png',
        ),
      ).thenThrow(const ServerFailure('upload failed'));

      final cubit = buildCubit();
      cubit.emit(ProfileLoaded(profile, tracks: [ownTrack]));
      return cubit;
    },
    act: (cubit) => cubit.uploadImage(
      imageType: ProfileImageType.AVATAR,
      filePath: '/tmp/a.png',
    ),
    expect: () => [
      isA<ProfileImageUploading>()
          .having((s) => s.imageType, 'imageType', ProfileImageType.AVATAR)
          .having((s) => s.tracks, 'tracks', [ownTrack]),
      isA<ProfileImageUploadError>()
          .having((s) => s.imageType, 'imageType', ProfileImageType.AVATAR)
          .having((s) => s.filePath, 'filePath', '/tmp/a.png')
          .having((s) => s.message, 'message', 'upload failed')
          .having((s) => s.tracks, 'tracks', [ownTrack]),
    ],
  );

  blocTest<ProfileCubit, ProfileState>(
    'uploadImage emits generic ProfileImageUploadError on unexpected exception',
    build: () {
      when(
        () => mockProfileRepository.uploadProfileImage(
          imageType: ProfileImageType.AVATAR,
          filePath: '/tmp/a.png',
        ),
      ).thenThrow(Exception('boom'));

      final cubit = buildCubit();
      cubit.emit(ProfileLoaded(profile, tracks: [ownTrack]));
      return cubit;
    },
    act: (cubit) => cubit.uploadImage(
      imageType: ProfileImageType.AVATAR,
      filePath: '/tmp/a.png',
    ),
    expect: () => [
      isA<ProfileImageUploading>(),
      isA<ProfileImageUploadError>().having(
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

  blocTest<ProfileCubit, ProfileState>(
    'uploadImage retries successfully from ProfileImageUploadError state',
    build: () {
      when(
        () => mockProfileRepository.uploadProfileImage(
          imageType: ProfileImageType.AVATAR,
          filePath: '/tmp/a.png',
        ),
      ).thenAnswer((_) async => 'avatar-updated');

      final cubit = buildCubit();
      cubit.emit(
        ProfileImageUploadError(
          profile,
          imageType: ProfileImageType.AVATAR,
          filePath: '/tmp/a.png',
          message: 'upload failed',
          tracks: [ownTrack],
        ),
      );
      return cubit;
    },
    act: (cubit) => cubit.uploadImage(
      imageType: ProfileImageType.AVATAR,
      filePath: '/tmp/a.png',
    ),
    expect: () => [
      isA<ProfileImageUploading>()
          .having((s) => s.tracks, 'tracks', [ownTrack]),
      isA<ProfileLoaded>()
          .having((s) => s.profile.avatarUrl, 'avatarUrl', 'avatar-updated')
          .having((s) => s.tracks, 'tracks', [ownTrack]),
    ],
  );
}
