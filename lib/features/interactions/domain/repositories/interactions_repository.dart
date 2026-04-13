import '../../../upload/domain/entities/managed_track.dart';
import '../entities/interaction_status.dart';
import '../entities/paginated_engagement_users.dart';

abstract class InteractionsRepository {
  Future<void> likeTrack(String trackId);
  Future<void> unlikeTrack(String trackId);
  Future<void> repostTrack(String trackId);
  Future<void> unrepostTrack(String trackId);
  Future<InteractionStatus> getTrackInteractionStatus(String trackId);

  Future<PaginatedEngagementUsers> getTrackLikers(
    String trackId, {
    int page = 1,
    int limit = 20,
  });

  Future<PaginatedEngagementUsers> getTrackReposters(
    String trackId, {
    int page = 1,
    int limit = 20,
  });

  Future<List<ManagedTrack>> getMyLikedTracks();

  Future<List<ManagedTrack>> getMyRepostedTracks();
}