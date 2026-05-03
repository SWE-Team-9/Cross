import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/usecases/get_track_by_secret_use_case.dart';
import '../../domain/usecases/get_track_detail_use_case.dart';
import 'player_cubit.dart';
import 'track_loader_state.dart';

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
  final PlayerCubit _playerCubit;

  Future<void> loadByTrackId(String trackId) async {
    if (trackId.isEmpty) {
      emit(const TrackLoaderError(message: 'Invalid track link.'));
      return;
    }

    emit(const TrackLoaderLoading());

    final result = await _getTrackDetail(trackId);

    if (result.failure != null) {
      emit(TrackLoaderError(message: _mapFailureMessage(result.failure!)));
      return;
    }

    final detail = result.detail!;
    unawaited(_playerCubit.play(detail.toPlaybackTrack()));
    emit(TrackLoaderReady(detail: detail));
  }

  Future<void> loadBySecretToken(String secretToken) async {
    if (secretToken.isEmpty) {
      emit(const TrackLoaderError(message: 'Invalid share link.'));
      return;
    }

    emit(const TrackLoaderLoading());

    final result = await _getTrackBySecret(secretToken);

    if (result.failure != null) {
      emit(TrackLoaderError(message: _mapFailureMessage(result.failure!)));
      return;
    }

    final detail = result.detail!;
    unawaited(_playerCubit.play(detail.toPlaybackTrack()));
    emit(TrackLoaderReady(detail: detail));
  }

  // ✅ الجديد
  Future<void> loadBySlug(String handle, String slug) async {
    if (handle.isEmpty || slug.isEmpty) {
      emit(const TrackLoaderError(message: 'Invalid track link.'));
      return;
    }

    emit(const TrackLoaderLoading());

    final result = await _getTrackDetail.callBySlug(handle, slug);

    if (result.failure != null) {
      emit(TrackLoaderError(message: _mapFailureMessage(result.failure!)));
      return;
    }

    final detail = result.detail!;
    unawaited(_playerCubit.play(detail.toPlaybackTrack()));
    emit(TrackLoaderReady(detail: detail));
  }

  String _mapFailureMessage(Failure failure) {
    return switch (failure) {
      NotFoundFailure() => 'This link is no longer valid.',
      ForbiddenFailure() => 'This track is not available for playback.',
      NetworkFailure() => 'No internet connection. Please try again.',
      AuthFailure() => 'Please log in to listen to this track.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
