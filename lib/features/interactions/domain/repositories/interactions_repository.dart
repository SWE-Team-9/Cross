import '../entities/interaction_status.dart';

abstract class InteractionsRepository {
  Future<void> likeTrack(String trackId);
  Future<void> unlikeTrack(String trackId);
  Future<void> repostTrack(String trackId);
  Future<void> unrepostTrack(String trackId);
  Future<InteractionStatus> getTrackInteractionStatus(String trackId);
}