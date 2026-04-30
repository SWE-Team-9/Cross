import '../../domain/entities/conversation_list_page_entity.dart';
import 'conversation_dto.dart';

class ConversationListPageDto {
  final List<ConversationDto> conversations;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  const ConversationListPageDto({
    required this.conversations,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  factory ConversationListPageDto.fromJson(Map<String, dynamic> json) {
    final rawList = json['conversations'] ??
        json['items'] ??
        json['results'] ??
        json['data'] ??
        const [];

    final conversations = rawList is List
        ? rawList
            .whereType<Map>()
            .map((item) => ConversationDto.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false)
        : const <ConversationDto>[];

    final page = _toInt(json['page']) ?? 1;
    final limit = _toInt(json['limit']) ?? conversations.length;
    final total = _toInt(json['total']) ?? conversations.length;
    final explicitHasMore = _toBool(json['hasMore'] ?? json['has_more']);

    return ConversationListPageDto(
      conversations: conversations,
      page: page,
      limit: limit,
      total: total,
      hasMore: explicitHasMore ?? (page * limit < total),
    );
  }

  ConversationListPageEntity toEntity() {
    return ConversationListPageEntity(
      conversations: conversations.map((dto) => dto.toEntity()).toList(),
      page: page,
      limit: limit,
      total: total,
      hasMore: hasMore,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final normalized = value.toString().toLowerCase().trim();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }
}
