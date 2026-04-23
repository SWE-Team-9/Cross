import '../../domain/entities/conversation_list_page_entity.dart';
import 'conversation_dto.dart';

class ConversationListPageDto {
  final int page;
  final int limit;
  final int total;
  final List<ConversationDto> conversations;

  const ConversationListPageDto({
    required this.page,
    required this.limit,
    required this.total,
    required this.conversations,
  });

  factory ConversationListPageDto.fromJson(Map<String, dynamic> json) {
    final rawList = json['conversations'] is List
        ? List<dynamic>.from(json['conversations'] as List)
        : const <dynamic>[];

    return ConversationListPageDto(
      page: _toInt(json['page']) ?? 1,
      limit: _toInt(json['limit']) ?? 20,
      total: _toInt(json['total']) ?? rawList.length,
      conversations: rawList
          .map(
            (item) => ConversationDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  ConversationListPageEntity toEntity() {
    return ConversationListPageEntity(
      page: page,
      limit: limit,
      total: total,
      conversations: conversations.map((e) => e.toEntity()).toList(
            growable: false,
          ),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }
}