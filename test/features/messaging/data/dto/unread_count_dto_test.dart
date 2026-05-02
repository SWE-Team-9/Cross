import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/unread_count_dto.dart';

void main() {
  group('UnreadCountDto', () {
    test('fromJson reads integer count', () {
      final dto = UnreadCountDto.fromJson(<String, dynamic>{
        'count': 7,
      });

      expect(dto.count, 7);
    });

    test('fromJson rounds numeric count', () {
      final dto = UnreadCountDto.fromJson(<String, dynamic>{
        'count': 7.6,
      });

      expect(dto.count, 8);
    });

    test('fromJson parses string count', () {
      final dto = UnreadCountDto.fromJson(<String, dynamic>{
        'count': '12',
      });

      expect(dto.count, 12);
    });

    test('fromJson defaults invalid count to zero', () {
      final dto = UnreadCountDto.fromJson(<String, dynamic>{
        'count': 'invalid',
      });

      expect(dto.count, 0);
    });

    test('fromJson defaults missing count to zero', () {
      final dto = UnreadCountDto.fromJson(<String, dynamic>{});

      expect(dto.count, 0);
    });

    test('toEntity maps count', () {
      const dto = UnreadCountDto(count: 9);

      final entity = dto.toEntity();

      expect(entity.count, 9);
    });
  });
}
