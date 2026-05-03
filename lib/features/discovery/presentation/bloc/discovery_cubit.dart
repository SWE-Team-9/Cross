import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/resolved_resource.dart';
import '../../domain/usecases/resolve_resource_usecase.dart';

part 'discovery_state.dart';

class DiscoveryCubit extends Cubit<DiscoveryState> {
  DiscoveryCubit(this._resolveResource) : super(const DiscoveryInitial());

  final ResolveResourceUseCase _resolveResource;

  Future<void> resolve(String url) async {
    if (isClosed) return;
    if (url.trim().isEmpty) return;

    _emitIfOpen(const DiscoveryLoading());
    try {
      final resource = await _resolveResource(url.trim());
      _emitIfOpen(DiscoveryResolved(resource));
    } catch (e) {
      _emitIfOpen(DiscoveryError(e.toString()));
    }
  }

  void reset() => _emitIfOpen(const DiscoveryInitial());

  void _emitIfOpen(DiscoveryState nextState) {
    if (!isClosed) emit(nextState);
  }
}
