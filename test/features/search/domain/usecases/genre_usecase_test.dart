import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/search/domain/entities/genre_entities.dart';
import 'package:soundcloud_clone/features/search/domain/repositories/genre_repository.dart';
import 'package:soundcloud_clone/features/search/domain/usecases/genre_usecase.dart';

class MockGenreRepository extends Mock implements GenreRepository {}

void main() {
  late GenreUseCase genreUseCase;
  late FollowUserUseCase followUserUseCase;
  late MockGenreRepository mockRepository;

  setUp(() {
    mockRepository = MockGenreRepository();
    genreUseCase = GenreUseCase(mockRepository);
    followUserUseCase = FollowUserUseCase(mockRepository);
  });

  group('GenreUseCase', () {
    const tGenreQuery = 'electronic';
    final tGenreData = GenrePageData(
      headerImageUrl: 'https://example.com/header.png',
      trending: const [
        Track(
          id: 't1',
          title: 'Electronic Beat',
          artist: 'DJ Test',
          audioUrl: 'https://example.com/track.mp3',
          artworkUrl: 'https://example.com/art.png',
          handle: 'dj-test',
          slug: 'electronic-beat',
          artistId: 'a1',
          likesCount: 0,
          repostsCount: 0,
          durationMs: 180000,
        ),
      ],
      discoverMore: const [],
      followingIds: const {'u1'},
    );

    test('returns genre page data when repository returns Right', () async {
      when(() => mockRepository.fetchGenrePage(tGenreQuery))
          .thenAnswer((_) async => Right(tGenreData));

      final result = await genreUseCase(tGenreQuery);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => throw Exception()).headerImageUrl,
          equals(tGenreData.headerImageUrl));
      expect(result.getOrElse(() => throw Exception()).trending.length, 1);
      expect(result.getOrElse(() => throw Exception()).followingIds,
          equals(tGenreData.followingIds));
      verify(() => mockRepository.fetchGenrePage(tGenreQuery)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('passes genre query to repository without modification', () async {
      when(() => mockRepository.fetchGenrePage(tGenreQuery))
          .thenAnswer((_) async => Right(tGenreData));

      await genreUseCase(tGenreQuery);

      verify(() => mockRepository.fetchGenrePage(tGenreQuery)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('rethrows failures from repository', () async {
      when(() => mockRepository.fetchGenrePage(tGenreQuery)).thenThrow(
        const NotFoundFailure('Genre not found'),
      );

      expect(
        () async => await genreUseCase(tGenreQuery),
        throwsA(isA<NotFoundFailure>()),
      );
      verify(() => mockRepository.fetchGenrePage(tGenreQuery)).called(1);
    });
  });

  group('FollowUserUseCase', () {
    const tUserId = 'u1';
    const tFollow = true;

    test('calls repository followUser with correct values', () async {
      when(() => mockRepository.followUser(userId: tUserId, follow: tFollow))
          .thenAnswer((_) async => const Right(null));

      final result = await followUserUseCase(userId: tUserId, follow: tFollow);

      expect(result.isRight(), true);
      verify(() => mockRepository.followUser(userId: tUserId, follow: tFollow))
          .called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('rethrows failures from repository during followUser', () async {
      when(() => mockRepository.followUser(userId: tUserId, follow: tFollow))
          .thenThrow(const AuthFailure('Not allowed'));

      expect(
        () async => await followUserUseCase(userId: tUserId, follow: tFollow),
        throwsA(isA<AuthFailure>()),
      );
      verify(() => mockRepository.followUser(userId: tUserId, follow: tFollow))
          .called(1);
    });
  });
}
