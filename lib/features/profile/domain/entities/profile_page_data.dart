import '../../../playlists/domain/entities/playlist_entity.dart';
import 'profile_entity.dart';

class ProfilePageData {
  final ProfileEntity profile;
  final List<PlaylistEntity> playlists;
  final List<PlaylistEntity> likedPlaylists;

  const ProfilePageData({
    required this.profile,
    this.playlists = const <PlaylistEntity>[],
    this.likedPlaylists = const <PlaylistEntity>[],
  });
}
