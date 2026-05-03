import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/home/domain/entities/home_content.dart';
import 'package:soundcloud_clone/features/home/domain/repositories/home_repository.dart';
import 'package:soundcloud_clone/features/home/domain/usecases/get_home_content_usecase.dart';
import 'package:soundcloud_clone/features/home/domain/usecases/get_home_trending_tracks_usecase.dart';
import 'package:soundcloud_clone/features/home/presentation/bloc/home_cubit.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

void main() {
  group('HomeCubit lifecycle', () {
    test('load does not emit after close when request finishes late', () async {
      final repository = _FakeHomeRepository();
      final cubit = HomeCubit(
        getHomeContent: GetHomeContentUseCase(repository),
        getHomeTrendingTracks: GetHomeTrendingTracksUseCase(repository),
      );

      final loadFuture = cubit.load();
      await cubit.close();

      repository.completeAll();

      await expectLater(loadFuture, completes);
    });

    test('selectGenre does not emit after close when request finishes late',
        () async {
      final repository = _FakeHomeRepository();
      final cubit = HomeCubit(
        getHomeContent: GetHomeContentUseCase(repository),
        getHomeTrendingTracks: GetHomeTrendingTracksUseCase(repository),
      );

      final selectFuture = cubit.selectGenre('electronic');
      await cubit.close();

      repository.trendingTracks.complete(const <Track>[]);

      await expectLater(selectFuture, completes);
    });
  });
}

class _FakeHomeRepository implements HomeRepository {
  final favoriteGenres = Completer<List<String>>();
  final topPlaylists = Completer<HomeTopPlaylists>();
  final trendingTracks = Completer<List<Track>>();

  @override
  Future<List<String>> getFavoriteGenres() => favoriteGenres.future;

  @override
  Future<HomeTopPlaylists> getTopPlaylists({int limit = 10}) {
    return topPlaylists.future;
  }

  @override
  Future<List<Track>> getTrendingTracks({
    required String genre,
    int limit = 5,
  }) {
    return trendingTracks.future;
  }

  void completeAll() {
    if (!favoriteGenres.isCompleted) {
      favoriteGenres.complete(const <String>[HomeContent.topLikedGenre]);
    }
    if (!topPlaylists.isCompleted) {
      topPlaylists.complete(
        const HomeTopPlaylists(
          overallPlaylists: <PlaylistEntity>[],
          genreGroups: <HomeTopPlaylistGroup>[],
        ),
      );
    }
    if (!trendingTracks.isCompleted) {
      trendingTracks.complete(const <Track>[]);
    }
  }
}
