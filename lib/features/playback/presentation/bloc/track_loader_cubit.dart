// playback/presentation/bloc/track_loader_cubit.dart

// Dart SDK
import 'dart:async';

// Third-party
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

// Project
import '../../../../core/errors/failure.dart';
import '../../domain/usecases/get_track_by_secret_use_case.dart';
import '../../domain/usecases/get_track_detail_use_case.dart';
import 'player_cubit.dart';
import 'track_loader_state.dart';

/// Owns the lifecycle of fetching a track before playback.
///
/// Used exclusively by [TrackDeepLinkBridgePage].
///
/// Flow:
///   1. Call [loadByTrackId] or [loadBySecretToken]
///   2. Emits [TrackLoaderLoading]
///   3. On success → emits [TrackLoaderReady] + calls PlayerCubit.play()
///   4. On failure → emits [TrackLoaderError] with user-facing message
///
/// @injectable (not lazySingleton) — fresh instance per bridge page.
@injectable
class TrackLoaderCubit extends Cubit<TrackLoaderState> {
  TrackLoaderCubit({
    required GetTrackDetailUseCase getTrackDetail,
    required GetTrackBySecretUseCase getTrackBySecret,
    required PlayerCubit playerCubit,
  })  : _getTrackDetail = getTrackDetail,
        _getTrackBySecret = getTrackBySecret,
        _playerCubit = playerCubit,
        super(const TrackLoaderIdle());

  final GetTrackDetailUseCase _getTrackDetail;
  final GetTrackBySecretUseCase _getTrackBySecret;

  /// Reference to the singleton PlayerCubit — we call play() on it
  /// once the track is loaded. We don't own it, just use it.
  final PlayerCubit _playerCubit;

  /// Loads a public track by its UUID.
  /// Called when deep link is soundclone://track/{trackId}
  Future<void> loadByTrackId(String trackId) async {
    if (isClosed) return;

    if (trackId.isEmpty) {
      _emitIfOpen(const TrackLoaderError(message: 'Invalid track link.'));
      return;
    }

    _emitIfOpen(const TrackLoaderLoading());

    final result = await _getTrackDetail(trackId);
    if (isClosed) return;

    if (result.failure != null) {
      _emitIfOpen(
        TrackLoaderError(message: _mapFailureMessage(result.failure!)),
      );
      return;
    }

    final detail = result.detail!;
    // Hand off to PlayerCubit — converts TrackDetail → Track internally
    unawaited(_playerCubit.play(detail.toPlaybackTrack()));

    _emitIfOpen(TrackLoaderReady(detail: detail));
  }

  /// Loads a private track by its secret share token.
  /// Called when deep link is soundclone://track/secret/{token}
  Future<void> loadBySecretToken(String secretToken) async {
    if (isClosed) return;

    if (secretToken.isEmpty) {
      _emitIfOpen(const TrackLoaderError(message: 'Invalid share link.'));
      return;
    }

    _emitIfOpen(const TrackLoaderLoading());

    final result = await _getTrackBySecret(secretToken);
    if (isClosed) return;

    if (result.failure != null) {
      _emitIfOpen(
        TrackLoaderError(message: _mapFailureMessage(result.failure!)),
      );
      return;
    }

    final detail = result.detail!;

    unawaited(_playerCubit.play(detail.toPlaybackTrack()));

    _emitIfOpen(TrackLoaderReady(detail: detail));
  }

  /// Maps domain [Failure] types to user-facing strings.
  /// Presentation layer decides what the user sees — not the repository.
  String _mapFailureMessage(Failure failure) {
    return switch (failure) {
      NotFoundFailure() => 'This link is no longer valid.',
      ForbiddenFailure() => 'This track is not available for playback.',
      NetworkFailure() => 'No internet connection. Please try again.',
      AuthFailure() => 'Please log in to listen to this track.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  void _emitIfOpen(TrackLoaderState nextState) {
    if (!isClosed) emit(nextState);
  }
}
