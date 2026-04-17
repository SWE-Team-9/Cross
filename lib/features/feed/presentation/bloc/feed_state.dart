// ─────────────────────────────────────────────────────────────────────────────
//  feed_state.dart  —  Cubit States
// ─────────────────────────────────────────────────────────────────────────────

import 'package:equatable/equatable.dart';
import '../../domain/entities/feed_item.dart';

enum FeedTab { following, discover }

extension FeedTabX on FeedTab {
  String get key => name; // 'following' | 'discover'
  String get label => this == FeedTab.following ? 'Following' : 'Discover';
}

// ─────────────────────────────────────────────────────────────────────────────

abstract class FeedState extends Equatable {
  final FeedTab tab;
  const FeedState(this.tab);
}

/// Initial load in progress (full-screen skeleton)
class FeedLoading extends FeedState {
  const FeedLoading(super.tab);
  @override
  List<Object?> get props => [tab];
}

/// Items loaded — normal feed
class FeedLoaded extends FeedState {
  final List<FeedItem> items;
  final int nextPage;
  final bool hasMore;
  final bool isLoadingMore; // footer spinner
  final bool isRefreshing; // pull-to-refresh

  const FeedLoaded({
    required FeedTab tab,
    required this.items,
    required this.nextPage,
    required this.hasMore,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  }) : super(tab);

  FeedLoaded copyWith({
    FeedTab? tab,
    List<FeedItem>? items,
    int? nextPage,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return FeedLoaded(
      tab: tab ?? this.tab,
      items: items ?? this.items,
      nextPage: nextPage ?? this.nextPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props =>
      [tab, items, nextPage, hasMore, isLoadingMore, isRefreshing];
}

/// No items returned
class FeedEmpty extends FeedState {
  const FeedEmpty(super.tab);
  @override
  List<Object?> get props => [tab];
}

/// Error occurred
class FeedError extends FeedState {
  final String message;
  const FeedError(super.tab, this.message);
  @override
  List<Object?> get props => [tab, message];
}
