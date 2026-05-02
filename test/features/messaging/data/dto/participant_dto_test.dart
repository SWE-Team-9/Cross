import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/participant_dto.dart';

void main() {
  group('ParticipantDto', () {
    test('fromJson reads primary fields', () {
      final dto = ParticipantDto.fromJson(<String, dynamic>{
        'id': 'user-1',
        'displayName': 'Listener One',
        'handle': '@listener',
        'avatarUrl': 'https://example.com/avatar.png',
      });

      expect(dto.id, 'user-1');
      expect(dto.displayName, 'Listener One');
      expect(dto.handle, '@listener');
      expect(dto.avatarUrl, 'https://example.com/avatar.png');
    });

    test('fromJson reads snake_case and fallback fields', () {
      final dto = ParticipantDto.fromJson(<String, dynamic>{
        '_id': 'user-2',
        'display_name': 'Listener Two',
        'username': 'listener_two',
        'avatar_url': 'https://example.com/avatar-2.png',
      });

      expect(dto.id, 'user-2');
      expect(dto.displayName, 'Listener Two');
      expect(dto.handle, 'listener_two');
      expect(dto.avatarUrl, 'https://example.com/avatar-2.png');
    });

    test('fromJson reads userId and profileImageUrl aliases', () {
      final dto = ParticipantDto.fromJson(<String, dynamic>{
        'userId': 'user-3',
        'name': 'Listener Three',
        'username': 'listener_three',
        'profileImageUrl': 'https://example.com/avatar-3.png',
      });

      expect(dto.id, 'user-3');
      expect(dto.displayName, 'Listener Three');
      expect(dto.handle, 'listener_three');
      expect(dto.avatarUrl, 'https://example.com/avatar-3.png');
    });

    test('fromJson reads user_id and profile_image_url aliases', () {
      final dto = ParticipantDto.fromJson(<String, dynamic>{
        'user_id': 'user-4',
        'username': 'listener_four',
        'profile_image_url': 'https://example.com/avatar-4.png',
      });

      expect(dto.id, 'user-4');
      expect(dto.displayName, 'listener_four');
      expect(dto.handle, 'listener_four');
      expect(dto.avatarUrl, 'https://example.com/avatar-4.png');
    });

    test('fromJson uses safe defaults for missing values', () {
      final dto = ParticipantDto.fromJson(<String, dynamic>{});

      expect(dto.id, '');
      expect(dto.displayName, '');
      expect(dto.handle, '');
      expect(dto.avatarUrl, isNull);
    });

    test('fromJson converts non-string values to strings', () {
      final dto = ParticipantDto.fromJson(<String, dynamic>{
        'id': 123,
        'displayName': 456,
        'handle': 789,
        'avatarUrl': 101112,
      });

      expect(dto.id, '123');
      expect(dto.displayName, '456');
      expect(dto.handle, '789');
      expect(dto.avatarUrl, '101112');
    });

    test('toEntity maps all fields', () {
      const dto = ParticipantDto(
        id: 'user-1',
        displayName: 'Listener One',
        handle: '@listener',
        avatarUrl: 'https://example.com/avatar.png',
      );

      final entity = dto.toEntity();

      expect(entity.id, dto.id);
      expect(entity.displayName, dto.displayName);
      expect(entity.handle, dto.handle);
      expect(entity.avatarUrl, dto.avatarUrl);
    });
  });
}
