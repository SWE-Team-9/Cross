import 'message_type.dart';
import 'shared_playlist_entity.dart';
import 'shared_track_entity.dart';

class MessageEntity {
  final String id;
  final String conversationId;
  final String? senderId;
  final String? receiverId;
  final MessageType type;
  final String? text;
  final bool isRead;
  final DateTime createdAt;
  final SharedTrackEntity? sharedTrack;
  final SharedPlaylistEntity? sharedPlaylist;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.text,
    required this.isRead,
    required this.createdAt,
    required this.sharedTrack,
    required this.sharedPlaylist,
  });

  bool get isText => type == MessageType.text;
  bool get isTrackShare => type == MessageType.trackShare;
  bool get isPlaylistShare => type == MessageType.playlistShare;
}
