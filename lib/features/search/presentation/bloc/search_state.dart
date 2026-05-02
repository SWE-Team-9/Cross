// lib/features/search/presentation/bloc/search_state.dart
part of 'search_cubit.dart';

enum SearchStatus { idle, loading, success, failure }

enum SearchTab { all, tracks, people, playlists }

/// What the body should show
enum SearchBodyMode {
  idle,         // no query, no recents
  recents,      // query empty + has recents
  suggestions,  // typing — show suggestions
  loading,      // submitted — fetching
  results,      // submitted — got results
  empty,        // submitted — zero results
  failure,      // submitted — error
}

class SearchState extends Equatable {
  // ── Typing state ────────────────────────────────────────────────────────────
  final String typingQuery;          // live text in the field
  final List<String> suggestions;
  final bool isSuggestionsLoading;

  // ── Submitted state ─────────────────────────────────────────────────────────
  final String submittedQuery;       // what we actually searched for
  final SearchStatus status;
  final List<TrackEntity> tracks;
  final List<UserEntity> users;
  final List<PlaylistEntity> playlists;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final Failure? failure;

  // ── Recents ─────────────────────────────────────────────────────────────────
  final List<String> recentSearches;

  // ── Tab ─────────────────────────────────────────────────────────────────────
  final SearchTab activeTab;

  const SearchState({
    this.typingQuery = '',
    this.suggestions = const [],
    this.isSuggestionsLoading = false,
    this.submittedQuery = '',
    this.status = SearchStatus.idle,
    this.tracks = const [],
    this.users = const [],
    this.playlists = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.failure,
    this.recentSearches = const [],
    this.activeTab = SearchTab.all,
  });

  // ── Derived ─────────────────────────────────────────────────────────────────

  bool get hasResults =>
      tracks.isNotEmpty || users.isNotEmpty || playlists.isNotEmpty;

  bool get hasMore => currentPage < totalPages;

  SearchBodyMode get bodyMode {
    // User has submitted a search
    if (submittedQuery.isNotEmpty) {
      return switch (status) {
        SearchStatus.loading => SearchBodyMode.loading,
        SearchStatus.failure => SearchBodyMode.failure,
        SearchStatus.success when !hasResults => SearchBodyMode.empty,
        SearchStatus.success => SearchBodyMode.results,
        _ => SearchBodyMode.loading,
      };
    }

    // User is typing but hasn't submitted
    if (typingQuery.isNotEmpty) {
      if (isSuggestionsLoading && suggestions.isEmpty) {
        return SearchBodyMode.suggestions; // show skeleton/spinner
      }
      if (suggestions.isNotEmpty) return SearchBodyMode.suggestions;
    }

    // Idle
    if (recentSearches.isNotEmpty) return SearchBodyMode.recents;
    return SearchBodyMode.idle;
  }

  SearchState copyWith({
    String? typingQuery,
    List<String>? suggestions,
    bool? isSuggestionsLoading,
    String? submittedQuery,
    SearchStatus? status,
    List<TrackEntity>? tracks,
    List<UserEntity>? users,
    List<PlaylistEntity>? playlists,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    Failure? failure,
    List<String>? recentSearches,
    SearchTab? activeTab,
    bool clearFailure = false,
  }) {
    return SearchState(
      typingQuery: typingQuery ?? this.typingQuery,
      suggestions: suggestions ?? this.suggestions,
      isSuggestionsLoading:
          isSuggestionsLoading ?? this.isSuggestionsLoading,
      submittedQuery: submittedQuery ?? this.submittedQuery,
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      users: users ?? this.users,
      playlists: playlists ?? this.playlists,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : (failure ?? this.failure),
      recentSearches: recentSearches ?? this.recentSearches,
      activeTab: activeTab ?? this.activeTab,
    );
  }

  @override
  List<Object?> get props => [
        typingQuery,
        suggestions,
        isSuggestionsLoading,
        submittedQuery,
        status,
        tracks,
        users,
        playlists,
        currentPage,
        totalPages,
        isLoadingMore,
        failure,
        recentSearches,
        activeTab,
      ];
}