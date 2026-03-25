import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:soundcloud_clone/features/profile/data/dto/profile_dto.dart';
import 'package:soundcloud_clone/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/profile_entity.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

void main() {
  late MockProfileRemoteDataSource mockRemoteDataSource;
  late ProfileRepositoryImpl repository;

  final dto = ProfileDto(
    id: '1',
    displayName: 'Ali',
    handle: 'ali',
    bio: 'bio',
    location: 'Cairo, Egypt',
    avatarUrl: 'avatar',
    coverPhotoUrl: 'cover',
    accountType: 'LISTENER',
    favoriteGenres: const ['Rock'],
    socialLinks: const {'x': 'y'},
    visibility: 'PUBLIC',
    trackCount: 0,
    followersCount: 1,
    followingCount: 2,
  );

  setUp(() {
    mockRemoteDataSource = MockProfileRemoteDataSource();
    repository = ProfileRepositoryImpl(mockRemoteDataSource);
  });

  test('getProfile delegates to remote source and maps dto to entity',
      () async {
    when(() => mockRemoteDataSource.getProfile('ali'))
        .thenAnswer((_) async => dto);

    final result = await repository.getProfile('ali');

    expect(result, isA<ProfileEntity>());
    expect(result.displayName, 'Ali');
    verify(() => mockRemoteDataSource.getProfile('ali')).called(1);
  });

  test('updateProfile sends only provided displayName', () async {
    when(() => mockRemoteDataSource.updateProfile(any()))
        .thenAnswer((_) async => dto);

    await repository.updateProfile(displayName: 'Ali');

    final captured = verify(
      () => mockRemoteDataSource.updateProfile(captureAny()),
    ).captured.single as Map<String, dynamic>;

    expect(captured, {'display_name': 'Ali'});
  });

  test('updateProfile sends bio and location when provided', () async {
    when(() => mockRemoteDataSource.updateProfile(any()))
        .thenAnswer((_) async => dto);

    await repository.updateProfile(
      bio: 'new bio',
      location: 'Giza, Egypt',
    );

    final captured = verify(
      () => mockRemoteDataSource.updateProfile(captureAny()),
    ).captured.single as Map<String, dynamic>;

    expect(captured['bio'], 'new bio');
    expect(captured['location'], 'Giza, Egypt');
    expect(captured.length, 2);
  });

  test('updateProfile maps PUBLIC visibility correctly', () async {
    when(() => mockRemoteDataSource.updateProfile(any()))
        .thenAnswer((_) async => dto);

    await repository.updateProfile(
      visibility: ProfileVisibility.PUBLIC,
    );

    final captured = verify(
      () => mockRemoteDataSource.updateProfile(captureAny()),
    ).captured.single as Map<String, dynamic>;

    expect(captured['visibility'], 'PUBLIC');
  });

  test('updateProfile maps PRIVATE visibility correctly', () async {
    when(() => mockRemoteDataSource.updateProfile(any()))
        .thenAnswer((_) async => dto);

    await repository.updateProfile(
      visibility: ProfileVisibility.PRIVATE,
    );

    final captured = verify(
      () => mockRemoteDataSource.updateProfile(captureAny()),
    ).captured.single as Map<String, dynamic>;

    expect(captured['visibility'], 'PRIVATE');
  });

  test('updateProfile sends favoriteGenres when provided', () async {
    when(() => mockRemoteDataSource.updateProfile(any()))
        .thenAnswer((_) async => dto);

    await repository.updateProfile(
      favoriteGenres: const ['Rock', 'Jazz'],
    );

    final captured = verify(
      () => mockRemoteDataSource.updateProfile(captureAny()),
    ).captured.single as Map<String, dynamic>;

    expect(captured['favorite_genres'], ['Rock', 'Jazz']);
  });

  test('updateProfile returns mapped entity from remote dto', () async {
    when(() => mockRemoteDataSource.updateProfile(any()))
        .thenAnswer((_) async => dto);

    final result = await repository.updateProfile(
      displayName: 'Ali',
      bio: 'bio',
      location: 'Cairo, Egypt',
      favoriteGenres: const ['Rock'],
      visibility: ProfileVisibility.PUBLIC,
    );

    expect(result.handle, 'ali');
    expect(result.favoriteGenres, ['Rock']);
  });

  test('uploadProfileImage delegates to remote source', () async {
    when(
      () => mockRemoteDataSource.uploadProfileImage(
        imageType: ProfileImageType.AVATAR,
        filePath: '/tmp/a.png',
      ),
    ).thenAnswer((_) async => 'uploaded-url');

    final result = await repository.uploadProfileImage(
      imageType: ProfileImageType.AVATAR,
      filePath: '/tmp/a.png',
    );

    expect(result, 'uploaded-url');
    verify(
      () => mockRemoteDataSource.uploadProfileImage(
        imageType: ProfileImageType.AVATAR,
        filePath: '/tmp/a.png',
      ),
    ).called(1);
  });

  test('checkHandleAvailable delegates to remote source', () async {
    when(() => mockRemoteDataSource.checkHandleAvailable('ali'))
        .thenAnswer((_) async => true);

    final result = await repository.checkHandleAvailable('ali');

    expect(result, true);
    verify(() => mockRemoteDataSource.checkHandleAvailable('ali')).called(1);
  });
}
