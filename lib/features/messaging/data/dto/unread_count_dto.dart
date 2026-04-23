import '../../domain/entities/unread_count_entity.dart';

class UnreadCountDto {
  final int count;

  const UnreadCountDto({
    required this.count,
  });

  factory UnreadCountDto.fromJson(Map<String, dynamic> json) {
    return UnreadCountDto(
      count: _toInt(json['count']) ?? 0,
    );
  }

  UnreadCountEntity toEntity() {
    return UnreadCountEntity(count: count);
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }
}