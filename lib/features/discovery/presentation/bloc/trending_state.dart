// lib/features/discovery/presentation/cubit/trending_state.dart

part of 'trending_cubit.dart';

sealed class TrendingState {
  const TrendingState();
}

final class TrendingInitial extends TrendingState {
  const TrendingInitial();
}

final class TrendingLoading extends TrendingState {
  const TrendingLoading();
}

final class TrendingLoaded extends TrendingState {
  final List<TrendingTrack> tracks;
  const TrendingLoaded(this.tracks);
}

final class TrendingError extends TrendingState {
  final String message;
  const TrendingError(this.message);
}
