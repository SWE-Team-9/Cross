import '../../domain/entities/message_entity.dart';
import '../../domain/entities/message_type.dart';
import 'shared_playlist_dto.dart';
import 'shared_track_dto.dart';

class MessageDto {
  final String id;
  final String conversationId;
  final String? senderId;
  final String? receiverId;
  final MessageType type;
  final String? text;
  final bool isRead;
  final DateTime createdAt;
  final SharedTrackDto? sharedTrack;
  final SharedPlaylistDto? sharedPlaylist;

  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.text,
    required this.isRead,
    required this.createdAt,
    this.sharedTrack,
    this.sharedPlaylist,
  });

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    final source = _messageJson(json);

    final sharedTrackRaw =
        source['sharedTrack'] ?? source['shared_track'] ?? source['track'];
    final sharedTrackMap = sharedTrackRaw is Map
        ? Map<String, dynamic>.from(sharedTrackRaw)
        : null;

    final sharedPlaylistRaw = source['sharedPlaylist'] ??
        source['shared_playlist'] ??
        source['playlist'];
    final sharedPlaylistMap = sharedPlaylistRaw is Map
        ? Map<String, dynamic>.from(sharedPlaylistRaw)
        : null;

    return MessageDto(
      id: (source['id'] ??
              source['messageId'] ??
              source['message_id'] ??
              source['_id'] ??
              '')
          .toString(),
      conversationId: (source['conversationId'] ??
              source['conversation_id'] ??
              source['conversation'] ??
              '')
          .toString(),
      senderId: _nullableString(source['senderId'] ?? source['sender_id']),
      receiverId:
          _nullableString(source['receiverId'] ?? source['receiver_id']),
      type: _parseType(source, sharedTrackMap, sharedPlaylistMap),
      text: _nullableString(
        source['text'] ?? source['content'] ?? source['body'],
      ),
      isRead: _toBool(source['isRead'] ?? source['is_read']) ?? false,
      createdAt:
          _parseDateTime(source['createdAt'] ?? source['created_at']).toLocal(),
      sharedTrack: sharedTrackMap == null
          ? null
          : SharedTrackDto.fromJson(sharedTrackMap),
      sharedPlaylist: sharedPlaylistMap == null
          ? null
          : SharedPlaylistDto.fromJson(sharedPlaylistMap),
    );
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      text: text,
      isRead: isRead,
      createdAt: createdAt,
      sharedTrack: sharedTrack?.toEntity(),
      sharedPlaylist: sharedPlaylist?.toEntity(),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final parsed = value.toString().trim();
    return parsed.isEmpty ? null : parsed;
  }

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;

    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0).toUtc();
    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0).toUtc();
  }

  static Map<String, dynamic> _messageJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return _messageJson(data);
    }
    if (data is Map) {
      return _messageJson(Map<String, dynamic>.from(data));
    }

    final message = json['message'];
    if (message is Map<String, dynamic>) return message;
    if (message is Map) return Map<String, dynamic>.from(message);

    return json;
  }

  static MessageType _parseType(
    Map<String, dynamic> json,
    Map<String, dynamic>? sharedTrackMap,
    Map<String, dynamic>? sharedPlaylistMap,
  ) {
    final type = MessageTypeX.fromApi(json['type'] ?? json['messageType']);
    if (type != MessageType.unknown) return type;
    if (sharedTrackMap != null) return MessageType.trackShare;
    if (sharedPlaylistMap != null) return MessageType.playlistShare;
    if (_nullableString(json['text'] ?? json['content'] ?? json['body']) !=
        null) {
      return MessageType.text;
    }
    return MessageType.unknown;
  }
}
