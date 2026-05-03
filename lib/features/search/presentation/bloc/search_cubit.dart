import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/errors/failure.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../social/data/repositories/social_repo.dart';
import '../../domain/entities/search_entities.dart';
import '../../domain/usecases/search_usecase.dart';

part 'search_state.dart';

@injectable
class SearchCubit extends Cubit<SearchState> {
  final SearchUseCase _searchUseCase;

  SearchCubit(this._searchUseCase) : super(const SearchState()) {
    _loadRecents();
  }

  Timer? _suggestionDebounce;

  static const _suggestionDelay = Duration(milliseconds: 300);
  static const _recentKey = 'recent_searches';
  static const _maxRecents = 10;
  static const _pageSize = 20;

  // ══════════════════════════════════════════════════════════════════════════
  // RECENT SEARCHES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final recents = prefs.getStringList(_recentKey) ?? [];

    if (!isClosed) {
      emit(state.copyWith(recentSearches: recents));
    }
  }

  Future<void> _saveRecent(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final recents = List<String>.from(state.recentSearches);

    recents.remove(trimmed);
    recents.insert(0, trimmed);

    if (recents.length > _maxRecents) {
      recents.removeLast();
    }

    await prefs.setStringList(_recentKey, recents);

    if (!isClosed) {
      emit(state.copyWith(recentSearches: recents));
    }
  }

  Future<void> removeRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final recents = List<String>.from(state.recentSearches)..remove(query);

    await prefs.setStringList(_recentKey, recents);

    if (!isClosed) {
      emit(state.copyWith(recentSearches: recents));
    }
  }

  Future<void> clearRecents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);

    if (!isClosed) {
      emit(state.copyWith(recentSearches: const []));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TYPING — debounced suggestions only
  // ══════════════════════════════════════════════════════════════════════════

  void onQueryChanged(String query) {
    _suggestionDebounce?.cancel();

    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          typingQuery: '',
          submittedQuery: '',
          suggestions: const [],
          isSuggestionsLoading: false,
          status: SearchStatus.idle,
          tracks: const [],
          users: const [],
          playlists: const [],
          currentPage: 1,
          totalPages: 1,
          clearFailure: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        typingQuery: query,
        suggestions: const [],
        isSuggestionsLoading: true,
      ),
    );

    _suggestionDebounce = Timer(
      _suggestionDelay,
      () => _fetchSuggestions(query),
    );
  }

  Future<void> _fetchSuggestions(String query) async {
    if (isClosed) return;

    await Future<void>.delayed(const Duration(milliseconds: 150));

    if (isClosed) return;

    final q = query.trim().toLowerCase();

    final suggestions = <String>[
      query.trim(),
      '$q remix',
      '$q acoustic',
      '$q live',
      '$q ft.',
    ].where((value) => value.trim().isNotEmpty).take(5).toList();

    emit(
      state.copyWith(
        suggestions: suggestions,
        isSuggestionsLoading: false,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUBMIT
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> submitSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _suggestionDebounce?.cancel();
    await _saveRecent(trimmed);

    emit(
      state.copyWith(
        typingQuery: trimmed,
        submittedQuery: trimmed,
        suggestions: const [],
        isSuggestionsLoading: false,
        status: SearchStatus.loading,
        tracks: const [],
        users: const [],
        playlists: const [],
        currentPage: 1,
        totalPages: 1,
        isLoadingMore: false,
        clearFailure: true,
      ),
    );

    await _fetch(trimmed, page: 1);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB + PAGINATION
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> onTabChanged(SearchTab tab) async {
    if (state.activeTab == tab) return;

    final submittedQuery = state.submittedQuery;

    emit(
      state.copyWith(
        activeTab: tab,
        currentPage: 1,
        totalPages: 1,
        isLoadingMore: false,
        clearFailure: true,
      ),
    );

    if (submittedQuery.trim().isEmpty) return;

    emit(
      state.copyWith(
        status: SearchStatus.loading,
        tracks: const [],
        users: const [],
        playlists: const [],
      ),
    );

    await _fetch(submittedQuery, page: 1);
  }

  Future<void> loadNextPage() async {
    if (state.submittedQuery.isEmpty) return;
    if (state.isLoadingMore) return;
    if (!state.hasMore) return;

    await _fetch(
      state.submittedQuery,
      page: state.currentPage + 1,
      append: true,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRIVATE FETCH
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _fetch(
    String query, {
    required int page,
    bool append = false,
  }) async {
    if (append) {
      emit(state.copyWith(isLoadingMore: true));
    }

    final result = await _searchUseCase(
      query,
      type: _apiTypeForTab(state.activeTab),
      page: page,
      limit: _pageSize,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: SearchStatus.failure,
            failure: failure,
            isLoadingMore: false,
          ),
        );
      },
      (data) {
        final tracks = append ? [...state.tracks, ...data.tracks] : data.tracks;

        final users = append ? [...state.users, ...data.users] : data.users;

        final playlists =
            append ? [...state.playlists, ...data.playlists] : data.playlists;

        emit(
          state.copyWith(
            status: SearchStatus.success,
            tracks: tracks,
            users: users,
            playlists: playlists,
            currentPage: data.meta.currentPage,
            totalPages: data.meta.totalPages,
            isLoadingMore: false,
            clearFailure: true,
          ),
        );

        _loadFollowingAfterSearch();
      },
    );
  }

  String? _apiTypeForTab(SearchTab tab) {
    return switch (tab) {
      SearchTab.all => null,
      SearchTab.tracks => 'tracks',
      SearchTab.people => 'users',
      SearchTab.playlists => 'playlists',
    };
  }

  Future<void> loadFollowingState(String currentUserId) async {
    try {
      final repo = getIt<SocialRepo>();
      final following = await repo.getFollowing(currentUserId, 1, limit: 100);
      final followingIds = following.map((user) => user.id).toSet();

      final updatedUsers = state.users.map((user) {
        return UserEntity(
          id: user.id,
          username: user.username,
          displayName: user.displayName,
          avatarUrl: user.avatarUrl,
          followersCount: user.followersCount,
          trackCount: user.trackCount,
          verified: user.verified,
          city: user.city,
          country: user.country,
          isFollowing: followingIds.contains(user.id),
        );
      }).toList(growable: false);

      if (!isClosed) {
        emit(state.copyWith(users: updatedUsers));
      }
    } catch (_) {
      // Best-effort UI enhancement only.
    }
  }

  void _loadFollowingAfterSearch() {
    if (!getIt.isRegistered<AuthCubit>()) return;
    if (!getIt.isRegistered<SocialRepo>()) return;

    final authState = getIt<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final currentUserId = authState.user.id;
    if (currentUserId.isEmpty) return;

    unawaited(loadFollowingState(currentUserId));
  }

  @override
  Future<void> close() {
    _suggestionDebounce?.cancel();
    return super.close();
  }
}
