import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/offline_track_entitlement.dart';

void main() {
  group('OfflineTrackEntitlement', () {
    test('uses safe defaults', () {
      const entitlement = OfflineTrackEntitlement();

      expect(entitlement.trackId, '');
      expect(entitlement.title, '');
      expect(entitlement.artist, '');
      expect(entitlement.handle, '');
      expect(entitlement.durationMs, 0);
      expect(entitlement.coverArtUrl, isNull);
      expect(entitlement.downloadUrl, '');
      expect(entitlement.expiresAt, isNull);
      expect(entitlement.expiresInSeconds, 0);
      expect(entitlement.offlineTokenId, '');
      expect(entitlement.planCode, '');

      expect(entitlement.isAllowed, isTrue);
      expect(entitlement.isPro, isFalse);
      expect(entitlement.isGoPlus, isFalse);
      expect(entitlement.hasCoverArt, isFalse);
      expect(entitlement.hasDownloadUrl, isFalse);
      expect(entitlement.hasOfflineToken, isFalse);
      expect(entitlement.isExpired, isFalse);
      expect(entitlement.displayTitle, 'Untitled');
      expect(entitlement.displayArtist, 'Unknown artist');
      expect(entitlement.duration, Duration.zero);
    });

    test('parses camel case json', () {
      final expiresAt = DateTime.parse('2026-05-01T00:00:00.000Z');

      final entitlement = OfflineTrackEntitlement.fromJson(
        <String, dynamic>{
          'trackId': 'track-1',
          'title': 'Midnight Drive',
          'artist': 'Ali',
          'handle': 'ali',
          'durationMs': 180000,
          'coverArtUrl': 'https://cdn.example.com/cover.jpg',
          'downloadUrl': 'https://cdn.example.com/audio.mp3',
          'expiresAt': expiresAt.toIso8601String(),
          'expiresInSeconds': 900,
          'offlineTokenId': 'offline-token-1',
          'planCode': 'PRO',
        },
      );

      expect(entitlement.trackId, 'track-1');
      expect(entitlement.title, 'Midnight Drive');
      expect(entitlement.artist, 'Ali');
      expect(entitlement.handle, 'ali');
      expect(entitlement.durationMs, 180000);
      expect(entitlement.coverArtUrl, 'https://cdn.example.com/cover.jpg');
      expect(entitlement.downloadUrl, 'https://cdn.example.com/audio.mp3');
      expect(entitlement.expiresAt, expiresAt);
      expect(entitlement.expiresInSeconds, 900);
      expect(entitlement.offlineTokenId, 'offline-token-1');
      expect(entitlement.planCode, 'PRO');

      expect(entitlement.isAllowed, isTrue);
      expect(entitlement.isPro, isTrue);
      expect(entitlement.isGoPlus, isFalse);
      expect(entitlement.hasCoverArt, isTrue);
      expect(entitlement.hasDownloadUrl, isTrue);
      expect(entitlement.hasOfflineToken, isTrue);
      expect(entitlement.displayTitle, 'Midnight Drive');
      expect(entitlement.displayArtist, 'Ali');
      expect(entitlement.duration, const Duration(milliseconds: 180000));
    });

    test('parses snake case json', () {
      final entitlement = OfflineTrackEntitlement.fromJson(
        const <String, dynamic>{
          'track_id': 'track-2',
          'title': 'Night Walk',
          'artistName': 'IQA3 Artist',
          'artistHandle': 'iqa3',
          'duration_ms': 120000,
          'cover_art_url': 'https://cdn.example.com/cover-2.jpg',
          'download_url': 'https://cdn.example.com/audio-2.mp3',
          'expires_in_seconds': 600,
          'offline_token_id': 'offline-token-2',
          'plan_code': 'GO_PLUS',
        },
      );

      expect(entitlement.trackId, 'track-2');
      expect(entitlement.artist, 'IQA3 Artist');
      expect(entitlement.handle, 'iqa3');
      expect(entitlement.durationMs, 120000);
      expect(entitlement.isGoPlus, isTrue);
    });

    test('free plan is not allowed', () {
      const entitlement = OfflineTrackEntitlement(planCode: 'FREE');

      expect(entitlement.isAllowed, isFalse);
      expect(entitlement.isPro, isFalse);
      expect(entitlement.isGoPlus, isFalse);
    });

    test('copyWith updates and clears nullable fields', () {
      final original = OfflineTrackEntitlement(
        trackId: 'track-1',
        title: 'Original',
        coverArtUrl: 'https://cdn.example.com/cover.jpg',
        expiresAt: DateTime.parse('2026-05-01T00:00:00.000Z'),
        planCode: 'PRO',
      );

      final updated = original.copyWith(
        title: 'Updated',
        clearCoverArtUrl: true,
        clearExpiresAt: true,
        planCode: 'GO_PLUS',
      );

      expect(updated.trackId, 'track-1');
      expect(updated.title, 'Updated');
      expect(updated.coverArtUrl, isNull);
      expect(updated.expiresAt, isNull);
      expect(updated.planCode, 'GO_PLUS');
    });
  });
}
