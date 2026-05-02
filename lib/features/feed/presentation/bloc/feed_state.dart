// ─────────────────────────────────────────────────────────────────────────────
//  feed_state.dart  —  Cubit States
// ─────────────────────────────────────────────────────────────────────────────

import 'package:equatable/equatable.dart';
import '../../domain/entities/feed_item.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Feed States  (Activity feed — single tab, chronological)
// ─────────────────────────────────────────────────────────────────────────────

abstract class FeedState extends Equatable {
  const FeedState();
}

/// Initial load in progress (full-screen skeleton)
class FeedLoading extends FeedState {
  const FeedLoading();
  @override
  List<Object?> get props => [];
}

/// Items loaded — normal feed
class FeedLoaded extends FeedState {
  final List<FeedItem> items;
  final int nextPage;
  final bool hasMore;
  final bool isLoadingMore; // footer spinner
  final bool isRefreshing; // pull-to-refresh

  const FeedLoaded({
    required this.items,
    required this.nextPage,
    required this.hasMore,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });

  FeedLoaded copyWith({
    List<FeedItem>? items,
    int? nextPage,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return FeedLoaded(
      items: items ?? this.items,
      nextPage: nextPage ?? this.nextPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props =>
      [items, nextPage, hasMore, isLoadingMore, isRefreshing];
}

/// No items returned
class FeedEmpty extends FeedState {
  const FeedEmpty();
  @override
  List<Object?> get props => [];
}

/// Error occurred
class FeedError extends FeedState {
  final String message;
  const FeedError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─────────────────────────────────────────────────────────────────────────────
//  Search States
// ─────────────────────────────────────────────────────────────────────────────

abstract class SearchState extends Equatable {
  const SearchState();
}

class SearchIdle extends SearchState {
  const SearchIdle();
  @override
  List<Object?> get props => [];
}

class SearchLoading extends SearchState {
  const SearchLoading();
  @override
  List<Object?> get props => [];
}

class SearchLoaded extends SearchState {
  final SearchResults results;
  final String query;

  const SearchLoaded({required this.results, required this.query});

  @override
  List<Object?> get props => [results, query];
}

class SearchEmpty extends SearchState {
  final String query;
  const SearchEmpty(this.query);
  @override
  List<Object?> get props => [query];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─────────────────────────────────────────────────────────────────────────────
//  Trending States
// ─────────────────────────────────────────────────────────────────────────────

abstract class TrendingState extends Equatable {
  const TrendingState();
}

class TrendingLoading extends TrendingState {
  const TrendingLoading();
  @override
  List<Object?> get props => [];
}

class TrendingLoaded extends TrendingState {
  final List<TrendingTrack> tracks;
  const TrendingLoaded(this.tracks);
  @override
  List<Object?> get props => [tracks];
}

class TrendingError extends TrendingState {
  final String message;
  const TrendingError(this.message);
  @override
  List<Object?> get props => [message];
}
