import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/data/dto/track_status_dto.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_status.dart';

void main() {
  group('TrackStatusDto', () {
    test('fromJson maps values and toEntity maps to domain object', () {
      final dto = TrackStatusDto.fromJson(const {
        'trackId': 'trk-1',
        'status': 'FINISHED',
      });

      expect(dto.trackId, 'trk-1');
      expect(dto.status, TrackStatus.FINISHED);

      final entity = dto.toEntity();
      expect(entity.trackId, 'trk-1');
      expect(entity.status, TrackStatus.FINISHED);
      expect(entity.isTerminal, isTrue);
    });

    test('fromJson defaults empty id and processing status', () {
      final dto = TrackStatusDto.fromJson(const {});

      expect(dto.trackId, '');
      expect(dto.status, TrackStatus.PROCESSING);
    });
  });
}
