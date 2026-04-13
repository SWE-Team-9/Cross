import '../../domain/entities/paginated_engagement_users.dart';
import 'engagement_user_dto.dart';

class PaginatedEngagementUsersDto {
  final List<EngagementUserDto> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginatedEngagementUsersDto({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginatedEngagementUsersDto.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List? ?? const [])
        .map((e) =>
            EngagementUserDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final pagination = Map<String, dynamic>.from(
      (json['pagination'] as Map?) ?? const {},
    );

    return PaginatedEngagementUsersDto(
      items: itemsJson,
      page: _toInt(pagination['page'], fallback: 1),
      limit: _toInt(pagination['limit'], fallback: itemsJson.length),
      total: _toInt(pagination['total']),
      totalPages: _toInt(pagination['totalPages'], fallback: 1),
      hasNextPage: pagination['hasNextPage'] == true,
      hasPreviousPage: pagination['hasPreviousPage'] == true,
    );
  }

  PaginatedEngagementUsers toEntity() {
    return PaginatedEngagementUsers(
      items: items.map((e) => e.toEntity()).toList(),
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNextPage: hasNextPage,
      hasPreviousPage: hasPreviousPage,
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
