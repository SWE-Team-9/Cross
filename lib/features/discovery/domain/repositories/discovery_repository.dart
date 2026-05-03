import '../entities/resolved_resource.dart';

abstract class DiscoveryRepository {
  /// Resolves a permalink URL to an internal resource.
  /// e.g. soundcloud.com/ahmed-hassan-beats/layali-el-qahira
  Future<ResolvedResource> resolveUrl(String url);
}
