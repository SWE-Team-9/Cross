import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/playlists/data/datasources/playlists_remote_data_source.dart';
import 'package:soundcloud_clone/features/playlists/data/dto/playlist_dto.dart';
import 'package:soundcloud_clone/features/playlists/data/repositories/playlists_repository_impl.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

void main() {
  group('PlaylistsRepositoryImpl', () {
    late _FakePlaylistsRemoteDataSource remote;
    late PlaylistsRepositoryImpl repository;

    setUp(() {
      remote = _FakePlaylistsRemoteDataSource();
      repository = PlaylistsRepositoryImpl(remote);
    });

    test('getMyPlaylists enriches missing editable metadata', () async {
      remote.myPlaylists = <PlaylistDto>[
        _playlistDto(
          id: 'playlist-1',
          title: 'Original title',
          description: '',
          coverImageUrl: null,
          visibility: PlaylistVisibility.privatePlaylist,
        ),
      ];
      remote.editDetails['playlist-1'] = _playlistDto(
        id: 'playlist-1',
        title: 'Edited title',
        description: 'Edited description',
        coverImageUrl: 'https://cdn.example/cover.jpg',
        visibility: PlaylistVisibility.publicPlaylist,
      );

      final playlists = await repository.getMyPlaylists(page: 2, limit: 5);

      expect(remote.lastPage, 2);
      expect(remote.lastLimit, 5);
      expect(playlists, hasLength(1));
      expect(playlists.single.title, 'Edited title');
      expect(playlists.single.description, 'Edited description');
      expect(playlists.single.coverImageUrl, 'https://cdn.example/cover.jpg');
      expect(playlists.single.visibility, PlaylistVisibility.publicPlaylist);
    });

    test('getMyPlaylists keeps existing metadata and ignores edit failures',
        () async {
      remote.myPlaylists = <PlaylistDto>[
        _playlistDto(
          id: 'covered',
          title: 'Covered',
          coverImageUrl: 'https://cdn.example/existing.jpg',
        ),
        _playlistDto(id: 'fallback', title: 'Fallback'),
      ];
      remote.throwEditDetailsFor.add('fallback');

      final playlists = await repository.getMyPlaylists();

      expect(playlists.map((item) => item.title), <String>[
        'Covered',
        'Fallback',
      ]);
      expect(remote.editDetailsCalls, <String>['fallback']);
    });

    test('maps playlist reads and mutations to the remote data source',
        () async {
      remote.recentPlaylists = <PlaylistDto>[
        _playlistDto(id: 'recent', title: 'Recent'),
      ];
      remote.likedPlaylists = <PlaylistDto>[
        _playlistDto(id: 'liked', title: 'Liked', isLiked: false),
      ];
      remote.searchResults = <PlaylistDto>[
        _playlistDto(id: 'search', title: 'Search'),
      ];
      remote.details['details'] = _playlistDto(id: 'details', title: 'Details');
      remote.editDetails['edit'] = _playlistDto(id: 'edit', title: 'Edit');
      remote.secretPlaylist =
          _playlistDto(id: 'secret', title: 'Secret playlist');
      remote.embedCode = '<iframe></iframe>';
      remote.uploadedCoverUrl = 'https://cdn.example/uploaded.jpg';

      final created = await repository.createPlaylist(
        title: 'Created',
        description: 'Description',
        visibility: PlaylistVisibility.privatePlaylist,
        initialTrackIds: const <String>['track-1'],
      );
      final recent = await repository.getRecentPlaylists(limit: 3);
      final details = await repository.getPlaylistDetails('details');
      final edit = await repository.getPlaylistEditDetails('edit');
      final liked = await repository.getLikedPlaylists(page: 4, limit: 6);
      final search = await repository.searchPublicPlaylists(
        'lofi',
        page: 7,
        limit: 8,
      );
      final coverUrl = await repository.uploadPlaylistCover(
        playlistId: 'created',
        filePath: '/tmp/cover.png',
      );
      final secret = await repository.resolveSecretPlaylist('secret-token');
      final embedCode = await repository.getPlaylistEmbedCode('created');

      await repository.updatePlaylist(
        playlistId: 'created',
        title: 'Updated',
        description: 'Updated description',
        visibility: PlaylistVisibility.publicPlaylist,
      );
      await repository.deletePlaylist('created');
      await repository.likePlaylist('created');
      await repository.unlikePlaylist('created');
      await repository.addTrackToPlaylist(
        playlistId: 'created',
        trackId: 'track-2',
      );
      await repository.removeTrackFromPlaylist(
        playlistId: 'created',
        trackId: 'track-2',
      );
      await repository.reorderPlaylistTracks(
        playlistId: 'created',
        orderedTrackIds: const <String>['track-2', 'track-1'],
      );

      expect(created.title, 'Created');
      expect(remote.createdTrackIds, const <String>['track-1']);
      expect(recent.single.playlistId, 'recent');
      expect(remote.recentLimit, 3);
      expect(details.title, 'Details');
      expect(edit.title, 'Edit');
      expect(liked.single.isLiked, isTrue);
      expect(remote.lastLikedPage, 4);
      expect(remote.lastLikedLimit, 6);
      expect(search.single.playlistId, 'search');
      expect(remote.lastSearchQuery, 'lofi');
      expect(remote.lastSearchPage, 7);
      expect(remote.lastSearchLimit, 8);
      expect(coverUrl, 'https://cdn.example/uploaded.jpg');
      expect(secret.title, 'Secret playlist');
      expect(embedCode, '<iframe></iframe>');
      expect(remote.updatedPlaylistId, 'created');
      expect(remote.deletedPlaylistId, 'created');
      expect(remote.likedPlaylistId, 'created');
      expect(remote.unlikedPlaylistId, 'created');
      expect(remote.addedTrack, ('created', 'track-2'));
      expect(remote.removedTrack, ('created', 'track-2'));
      expect(remote.reorderedTrackIds, const <String>['track-2', 'track-1']);
    });
  });
}

PlaylistDto _playlistDto({
  required String id,
  required String title,
  String description = 'Description',
  PlaylistVisibility visibility = PlaylistVisibility.publicPlaylist,
  String? coverImageUrl,
  bool isLiked = false,
}) {
  return PlaylistDto(
    playlistId: id,
    title: title,
    description: description,
    visibility: visibility,
    secretToken: null,
    coverImageUrl: coverImageUrl,
    owner: const PlaylistOwner(id: 'owner-1', displayName: 'Owner One'),
    tracks: const [],
    tracksCount: 0,
    isLiked: isLiked,
  );
}

class _FakePlaylistsRemoteDataSource implements PlaylistsRemoteDataSource {
  List<PlaylistDto> myPlaylists = const <PlaylistDto>[];
  List<PlaylistDto> recentPlaylists = const <PlaylistDto>[];
  List<PlaylistDto> likedPlaylists = const <PlaylistDto>[];
  List<PlaylistDto> searchResults = const <PlaylistDto>[];
  final Map<String, PlaylistDto> details = <String, PlaylistDto>{};
  final Map<String, PlaylistDto> editDetails = <String, PlaylistDto>{};
  final Set<String> throwEditDetailsFor = <String>{};
  final List<String> editDetailsCalls = <String>[];
  PlaylistDto? secretPlaylist;
  String? uploadedCoverUrl;
  String embedCode = '';

  int? lastPage;
  int? lastLimit;
  int? recentLimit;
  int? lastLikedPage;
  int? lastLikedLimit;
  String? lastSearchQuery;
  int? lastSearchPage;
  int? lastSearchLimit;
  List<String> createdTrackIds = const <String>[];
  String? updatedPlaylistId;
  String? deletedPlaylistId;
  String? likedPlaylistId;
  String? unlikedPlaylistId;
  (String, String)? addedTrack;
  (String, String)? removedTrack;
  List<String> reorderedTrackIds = const <String>[];

  @override
  Future<List<PlaylistDto>> getMyPlaylists({
    int page = 1,
    int limit = 20,
  }) async {
    lastPage = page;
    lastLimit = limit;
    return myPlaylists;
  }

  @override
  Future<List<PlaylistDto>> getRecentPlaylists({int limit = 10}) async {
    recentLimit = limit;
    return recentPlaylists;
  }

  @override
  Future<PlaylistDto> createPlaylist({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
    List<String> initialTrackIds = const <String>[],
  }) async {
    createdTrackIds = initialTrackIds;
    return _playlistDto(
      id: 'created',
      title: title,
      description: description,
      visibility: visibility,
    );
  }

  @override
  Future<PlaylistDto> getPlaylistDetails(String playlistId) async {
    return details[playlistId] ??
        _playlistDto(id: playlistId, title: 'Details');
  }

  @override
  Future<PlaylistDto> getPlaylistEditDetails(String playlistId) async {
    editDetailsCalls.add(playlistId);
    if (throwEditDetailsFor.contains(playlistId))
      throw Exception('edit failed');
    return editDetails[playlistId] ??
        _playlistDto(id: playlistId, title: 'Edit');
  }

  @override
  Future<void> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
    PlaylistVisibility? visibility,
  }) async {
    updatedPlaylistId = playlistId;
  }

  @override
  Future<String?> uploadPlaylistCover({
    required String playlistId,
    required String filePath,
  }) async {
    return uploadedCoverUrl;
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    deletedPlaylistId = playlistId;
  }

  @override
  Future<List<PlaylistDto>> getLikedPlaylists({
    int page = 1,
    int limit = 20,
  }) async {
    lastLikedPage = page;
    lastLikedLimit = limit;
    return likedPlaylists;
  }

  @override
  Future<List<PlaylistDto>> searchPublicPlaylists(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    lastSearchQuery = query;
    lastSearchPage = page;
    lastSearchLimit = limit;
    return searchResults;
  }

  @override
  Future<void> likePlaylist(String playlistId) async {
    likedPlaylistId = playlistId;
  }

  @override
  Future<void> unlikePlaylist(String playlistId) async {
    unlikedPlaylistId = playlistId;
  }

  @override
  Future<void> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    addedTrack = (playlistId, trackId);
  }

  @override
  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    removedTrack = (playlistId, trackId);
  }

  @override
  Future<void> reorderPlaylistTracks({
    required String playlistId,
    required List<String> orderedTrackIds,
  }) async {
    reorderedTrackIds = orderedTrackIds;
  }

  @override
  Future<PlaylistDto> resolveSecretPlaylist(String secretToken) async {
    return secretPlaylist ?? _playlistDto(id: 'secret', title: secretToken);
  }

  @override
  Future<String> getPlaylistEmbedCode(String playlistId) async {
    return embedCode;
  }
}
