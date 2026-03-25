import 'package:soundcloud_clone/core/models/track.dart';

class RecentlyPlayedItem {
  final Track track;
  final DateTime playedAt;

  RecentlyPlayedItem({
    required this.track,
    required this.playedAt,
  });
}
