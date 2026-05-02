// lib/features/discovery/presentation/cubit/trending_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/trending_track.dart';
import '../../domain/usecases/get_trending_usecase.dart';

part 'trending_state.dart';

class TrendingCubit extends Cubit<TrendingState> {
  final GetTrendingUseCase _getTrendingUseCase;

  TrendingCubit({required GetTrendingUseCase getTrendingUseCase})
      : _getTrendingUseCase = getTrendingUseCase,
        super(const TrendingInitial());

  Future<void> loadTrending() async {
    emit(const TrendingLoading());

    final result = await _getTrendingUseCase();

    result.fold(
      (failure) => emit(TrendingError(failure.message)),
      (tracks) => emit(TrendingLoaded(tracks)),
    );
  }
}
