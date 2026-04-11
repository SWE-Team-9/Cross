// playback/presentation/bloc/track_loader_state.dart

// Third-party
import 'package:equatable/equatable.dart';

// Project
import '../../domain/entities/track_details.dart';

/// Represents every possible state of the track detail loading lifecycle.
///
/// Used by [TrackLoaderCubit] — separate from [PlayerUIState] which
/// owns playback controls. This state owns fetching only.
sealed class TrackLoaderState extends Equatable {
  const TrackLoaderState();
}

/// Initial state — no loading has started yet.
final class TrackLoaderIdle extends TrackLoaderState {
  const TrackLoaderIdle();

  @override
  List<Object?> get props => [];
}

/// Fetching track detail + stream URL from the API.
final class TrackLoaderLoading extends TrackLoaderState {
  const TrackLoaderLoading();

  @override
  List<Object?> get props => [];
}

/// Track detail fetched successfully and handed to PlayerCubit.
/// [detail] is kept here so the bridge page can read track info
/// for display while the player initializes.
final class TrackLoaderReady extends TrackLoaderState {
  const TrackLoaderReady({required this.detail});

  final TrackDetail detail;

  @override
  List<Object?> get props => [detail];
}

/// Fetching failed. [message] is the user-facing error string.
final class TrackLoaderError extends TrackLoaderState {
  const TrackLoaderError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
