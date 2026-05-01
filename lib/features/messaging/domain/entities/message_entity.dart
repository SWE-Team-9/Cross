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

  MessageEntity copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    MessageType? type,
    String? text,
    bool? isRead,
    DateTime? createdAt,
    SharedTrackEntity? sharedTrack,
    SharedPlaylistEntity? sharedPlaylist,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      text: text ?? this.text,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      sharedTrack: sharedTrack ?? this.sharedTrack,
      sharedPlaylist: sharedPlaylist ?? this.sharedPlaylist,
    );
  }

  bool get isText => type == MessageType.text;
  bool get isTrackShare => type == MessageType.trackShare;
  bool get isPlaylistShare => type == MessageType.playlistShare;
  bool get isDeleted => text == null || text!.trim().isEmpty;
}