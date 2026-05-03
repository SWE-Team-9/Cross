import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trending_track.dart';
import '../../domain/usecases/get_trending_usecase.dart';

part 'trending_state.dart';

class TrendingCubit extends Cubit<TrendingState> {
  final GetTrendingUseCase _getTrendingUseCase;

  TrendingCubit({
    required GetTrendingUseCase getTrendingUseCase,
  })  : _getTrendingUseCase = getTrendingUseCase,
        super(const TrendingInitial());

  Future<void> loadTrending({
    int limit = 20,
    int windowDays = 7,
  }) async {
    emit(const TrendingLoading());

    final result = await _getTrendingUseCase(
      limit: limit,
      windowDays: windowDays,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(TrendingError(failure.message)),
      (tracks) => emit(TrendingLoaded(tracks)),
    );
  }
}
