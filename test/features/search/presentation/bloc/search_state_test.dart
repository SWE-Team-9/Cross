import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/search/domain/entities/search_entities.dart';
import 'package:soundcloud_clone/features/search/presentation/bloc/search_cubit.dart';

void main() {
  group('SearchState bodyMode', () {
    test('idle when no submittedQuery and no recents', () {
      const state = SearchState();
      expect(state.bodyMode, SearchBodyMode.idle);
    });

    test('recents when no submittedQuery and recent searches exist', () {
      const state = SearchState(recentSearches: ['test']);
      expect(state.bodyMode, SearchBodyMode.recents);
    });

    test('suggestions while typing and loading', () {
      const state = SearchState(
        typingQuery: 'a',
        suggestions: [],
        isSuggestionsLoading: true,
      );
      expect(state.bodyMode, SearchBodyMode.suggestions);
    });

    test('suggestions while typing with loaded suggestions', () {
      const state = SearchState(
        typingQuery: 'a',
        suggestions: ['a remix'],
        isSuggestionsLoading: false,
      );
      expect(state.bodyMode, SearchBodyMode.suggestions);
    });

    test('loading when submitted query is active and status is loading', () {
      const state = SearchState(
        submittedQuery: 'test',
        status: SearchStatus.loading,
      );
      expect(state.bodyMode, SearchBodyMode.loading);
    });

    test('empty when submitted query success with no results', () {
      const state = SearchState(
        submittedQuery: 'test',
        status: SearchStatus.success,
        tracks: [],
        users: [],
        playlists: [],
      );
      expect(state.bodyMode, SearchBodyMode.empty);
    });

    test('results when submitted query success with results', () {
      // DateTime مش const فلازم نشيل const من الـ state دي
      final state = SearchState(
        submittedQuery: 'test',
        status: SearchStatus.success,
        tracks: [
          TrackEntity(
            id: '1',
            title: 'Title',
            artistName: 'Artist',
            artworkUrl: 'art.png',
            streamUrl: 'stream.mp3',
            duration: const Duration(seconds: 1),
            playbackCount: 0,
            likesCount: 0,
            genre: 'pop',
            isPrivate: false,
            createdAt: DateTime(2024, 1, 1), // ← مش const
          )
        ],
      );
      expect(state.bodyMode, SearchBodyMode.results);
    });

    test('failure when submitted query fails', () {
      // NetworkFailure بتاخد positional مش named
      const state = SearchState(
        submittedQuery: 'test',
        status: SearchStatus.failure,
        failure: NetworkFailure('No connection'), // ← positional
      );
      expect(state.bodyMode, SearchBodyMode.failure);
    });

    test('hasMore uses currentPage and totalPages', () {
      const state = SearchState(currentPage: 1, totalPages: 2);
      expect(state.hasMore, true);
    });

    test('copyWith clearFailure removes existing failure', () {
      const state = SearchState(
        failure: NetworkFailure('Fail'), // ← positional
      );
      final updated = state.copyWith(clearFailure: true);
      expect(updated.failure, isNull);
    });

    test('copyWith maintains values when not overridden', () {
      const state = SearchState(activeTab: SearchTab.people);
      final updated = state.copyWith(typingQuery: 'hello');
      expect(updated.activeTab, SearchTab.people);
      expect(updated.typingQuery, 'hello');
    });
  });
}
