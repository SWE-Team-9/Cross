import '../entities/resolved_resource.dart';
import '../repositories/discovery_repository.dart';

class ResolveResourceUseCase {
  const ResolveResourceUseCase(this._repository);

  final DiscoveryRepository _repository;

  Future<ResolvedResource> call(String url) => _repository.resolveUrl(url);
}