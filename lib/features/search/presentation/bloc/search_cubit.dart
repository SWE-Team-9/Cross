// lib/features/search/presentation/bloc/search_cubit.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/search_entities.dart';
import '../../domain/usecases/search_usecase.dart';
import '../../../../core/errors/failure.dart';
import '../../../social/data/repositories/social_repo.dart';
import '../../../../core/di/injector.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
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

  // ══════════════════════════════════════════════════════════════════════════
  // RECENT SEARCHES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final recents = prefs.getStringList(_recentKey) ?? [];
    if (!isClosed) emit(state.copyWith(recentSearches: recents));
  }

  Future<void> _saveRecent(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final recents = List<String>.from(state.recentSearches);
    recents.remove(trimmed);
    recents.insert(0, trimmed);
    if (recents.length > _maxRecents) recents.removeLast();
    await prefs.setStringList(_recentKey, recents);
    if (!isClosed) emit(state.copyWith(recentSearches: recents));
  }

  Future<void> removeRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final recents = List<String>.from(state.recentSearches)..remove(query);
    await prefs.setStringList(_recentKey, recents);
    if (!isClosed) emit(state.copyWith(recentSearches: recents));
  }

  Future<void> clearRecents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
    if (!isClosed) emit(state.copyWith(recentSearches: []));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TYPING — debounced suggestions only, NO results fetch
  // ══════════════════════════════════════════════════════════════════════════

  void onQueryChanged(String query) {
    _suggestionDebounce?.cancel();

    if (query.trim().isEmpty) {
      // Field cleared — reset to recents/idle, keep submitted results if any
      emit(state.copyWith(
        typingQuery: '',
        suggestions: [],
        isSuggestionsLoading: false,
        submittedQuery: '',            // clear submitted so bodyMode goes back
        status: SearchStatus.idle,
        tracks: [],
        users: [],
        playlists: [],
        clearFailure: true,
      ));
      return;
    }

    // Update typing query immediately (drives the field display)
    emit(state.copyWith(
      typingQuery: query,
      suggestions: [],
      isSuggestionsLoading: true,
    ));

    // Debounce suggestion fetch
    _suggestionDebounce = Timer(_suggestionDelay, () => _fetchSuggestions(query));
  }

  Future<void> _fetchSuggestions(String query) async {
    if (isClosed) return;

    // TODO: replace with real GET /api/v1/search/suggestions?q=query
    // For now generate mock suggestions from query
    await Future.delayed(const Duration(milliseconds: 150));
    if (isClosed) return;

    final q = query.trim().toLowerCase();
    final mocks = [
      query,
      '$q remix',
      '$q acoustic',
      '$q live',
      '$q ft.',
    ].where((s) => s.isNotEmpty).take(5).toList();

    if (!isClosed) {
      emit(state.copyWith(
        suggestions: mocks,
        isSuggestionsLoading: false,
      ));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUBMIT — user pressed search button or picked a suggestion/recent
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> submitSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _suggestionDebounce?.cancel();
    await _saveRecent(trimmed);

    emit(state.copyWith(
      typingQuery: trimmed,
      submittedQuery: trimmed,
      suggestions: [],
      isSuggestionsLoading: false,
      status: SearchStatus.loading,
      tracks: [],
      users: [],
      playlists: [],
      currentPage: 1,
      clearFailure: true,
    ));

    await _fetch(trimmed, page: 1);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB + PAGINATION
  // ══════════════════════════════════════════════════════════════════════════

  void onTabChanged(SearchTab tab) {
    if (state.activeTab == tab) return;
    emit(state.copyWith(activeTab: tab));
  }

  Future<void> loadNextPage() async {
    if (state.submittedQuery.isEmpty) return;
    if (state.isLoadingMore) return;
    if (!state.hasMore) return;
    await _fetch(state.submittedQuery, page: state.currentPage + 1, append: true);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRIVATE FETCH
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _fetch(String query, {required int page, bool append = false}) async {
    if (append) emit(state.copyWith(isLoadingMore: true));

    final result = await _searchUseCase(query, page: page);

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: SearchStatus.failure,
        failure: failure,
        isLoadingMore: false,
      )),
      (data) {
        if (append) {
          emit(state.copyWith(
            status: SearchStatus.success,
            tracks: [...state.tracks, ...data.tracks],
            users: [...state.users, ...data.users],
            playlists: [...state.playlists, ...data.playlists],
            currentPage: data.meta.currentPage,
            totalPages: data.meta.totalPages,
            isLoadingMore: false,
          ));
           _loadFollowingAfterSearch();
        } else {
          emit(state.copyWith(
            status: SearchStatus.success,
            tracks: data.tracks,
            users: data.users,
            playlists: data.playlists,
            currentPage: data.meta.currentPage,
            totalPages: data.meta.totalPages,
            isLoadingMore: false,
          ));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _suggestionDebounce?.cancel();
    return super.close();
  }

  // أضف في SearchCubit
Future<void> loadFollowingState(String currentUserId) async {
  try {
    final repo = getIt<SocialRepo>();
    final following = await repo.getFollowing(currentUserId, 1, limit: 100);
    final followingIds = following.map((u) => u.id).toSet();

    final updatedUsers = state.users.map((u) {
      return UserEntity(
        id: u.id,
        username: u.username,
        displayName: u.displayName,
        avatarUrl: u.avatarUrl,
        followersCount: u.followersCount,
        trackCount: u.trackCount,
        verified: u.verified,
        city: u.city,
        country: u.country,
        isFollowing: followingIds.contains(u.id),
      );
    }).toList();

    emit(state.copyWith(users: updatedUsers));
  } catch (_) {}
}

void _loadFollowingAfterSearch() {
  final authState = getIt<AuthCubit>().state;
  if (authState is! AuthAuthenticated) return;
  final currentUserId = authState.user.id;
  if (currentUserId.isEmpty) return;
  loadFollowingState(currentUserId);
}
}