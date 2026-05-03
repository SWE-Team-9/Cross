import 'package:equatable/equatable.dart';

import '../../domain/entities/feed_item.dart';

abstract class FeedState extends Equatable {
  const FeedState();
}

class FeedLoading extends FeedState {
  const FeedLoading();

  @override
  List<Object?> get props => [];
}

class FeedLoaded extends FeedState {
  final List<FeedItem> items;
  final int nextPage;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;

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
  List<Object?> get props => [
        items,
        nextPage,
        hasMore,
        isLoadingMore,
        isRefreshing,
      ];
}

class FeedEmpty extends FeedState {
  const FeedEmpty();

  @override
  List<Object?> get props => [];
}

class FeedError extends FeedState {
  final String message;

  const FeedError(this.message);

  @override
  List<Object?> get props => [message];
}
