import '../../domain/entities/resolved_resource.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../datasources/discovery_remote_data_source.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  const DiscoveryRepositoryImpl(this._dataSource);

  final DiscoveryRemoteDataSource _dataSource;

  @override
  Future<ResolvedResource> resolveUrl(String url) {
    return _dataSource.resolveUrl(url);
  }
}
