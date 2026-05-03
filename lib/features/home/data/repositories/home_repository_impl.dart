import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/discovery/data/datasources/discovery_remote_data_source.dart';
import 'package:soundcloud_clone/features/discovery/domain/entities/trending_track.dart';
import 'package:soundcloud_clone/features/home/data/datasources/home_remote_data_source.dart';
import 'package:soundcloud_clone/features/home/domain/entities/home_content.dart';
import 'package:soundcloud_clone/features/home/domain/repositories/home_repository.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl({
    required ProfileRepository profileRepository,
    required HomeRemoteDataSource homeRemoteDataSource,
    required DiscoveryRemoteDataSource discoveryRemoteDataSource,
  })  : _profileRepository = profileRepository,
        _homeRemoteDataSource = homeRemoteDataSource,
        _discoveryRemoteDataSource = discoveryRemoteDataSource;

  final ProfileRepository _profileRepository;
  final HomeRemoteDataSource _homeRemoteDataSource;
  final DiscoveryRemoteDataSource _discoveryRemoteDataSource;

  static const List<String> _supportedGenres = <String>[
    HomeContent.topLikedGenre,
    'electronic',
    'hip-hop',
    'pop',
    'rock',
    'alternative',
    'ambient',
    'classical',
    'jazz',
    'r-b-soul',
    'metal',
    'folk-singer-songwriter',
    'country',
    'reggaeton',
    'dancehall',
    'drum-bass',
    'house',
    'techno',
    'deep-house',
    'trance',
    'lo-fi',
    'indie',
    'punk',
    'blues',
    'latin',
    'afrobeat',
    'trap',
    'experimental',
    'world',
    'gospel',
    'spoken-word',
    'sha3by',
    'islamic',
  ];

  @override
  Future<List<String>> getFavoriteGenres() async {
    final profile = await _profileRepository.getMyProfile();
    final genres = profile.favoriteGenres
        .map(_normalizeGenre)
        .where((genre) => genre.isNotEmpty && genre != 'quran')
        .where(_supportedGenres.contains)
        .toSet()
        .toList(growable: false);

    return <String>[
      HomeContent.topLikedGenre,
      ...genres,
    ];
  }

  @override
  Future<HomeTopPlaylists> getTopPlaylists({int limit = 10}) {
    return _homeRemoteDataSource.getTopPlaylists(limit: limit);
  }

  @override
  Future<List<Track>> getTrendingTracks({
    required String genre,
    int limit = 5,
  }) async {
    final tracks = genre == HomeContent.topLikedGenre
        ? await _discoveryRemoteDataSource.getTrending(limit: limit)
        : await _discoveryRemoteDataSource.getGenreTrendingTracks(
            genreSlug: _normalizeGenre(genre),
            limit: limit,
          );

    return tracks
        .where((track) => track.id.trim().isNotEmpty)
        .map(_toTrack)
        .toList(growable: false);
  }

  static String _normalizeGenre(String genre) {
    return genre.trim().toLowerCase();
  }

  static Track _toTrack(TrendingTrack track) {
    return Track(
      id: track.id,
      title: track.title.trim().isEmpty ? 'Untitled' : track.title.trim(),
      artist: track.ownerDisplayName.trim().isEmpty
          ? 'Unknown artist'
          : track.ownerDisplayName.trim(),
      audioUrl: track.audioUrl,
      artworkUrl: track.coverUrl.trim().isEmpty ? null : track.coverUrl.trim(),
      handle: track.ownerHandle.trim().isEmpty ? null : track.ownerHandle,
      artistId: track.ownerId.trim().isEmpty ? null : track.ownerId,
      genre: track.genre.trim().isEmpty ? null : track.genre,
      likesCount: track.likesCount,
      repostsCount: track.repostsCount,
      slug: track.slug,
    );
  }
}
