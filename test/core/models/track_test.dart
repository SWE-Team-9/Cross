import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/models/track.dart';

void main() {
  group('Track', () {
    test('duration returns null when durationMs is missing or invalid', () {
      expect(
        const Track(
          id: '1',
          title: 'No Duration',
          artist: 'Artist',
          audioUrl: 'https://example.com/track.mp3',
        ).duration,
        isNull,
      );

      expect(
        const Track(
          id: '1',
          title: 'Invalid Duration',
          artist: 'Artist',
          audioUrl: 'https://example.com/track.mp3',
          durationMs: 0,
        ).duration,
        isNull,
      );
    });

    test('duration maps positive milliseconds to Duration', () {
      const track = Track(
        id: '1',
        title: 'With Duration',
        artist: 'Artist',
        audioUrl: 'https://example.com/track.mp3',
        durationMs: 123000,
      );

      expect(track.duration, const Duration(seconds: 123));
    });

    test('copyWith keeps existing values and replaces supplied fields', () {
      const track = Track(
        id: '1',
        title: 'Original',
        artist: 'Artist',
        audioUrl: 'https://example.com/original.mp3',
        artworkUrl: 'https://example.com/art.jpg',
        handle: 'artist',
        artistId: 'artist-1',
        likesCount: 4,
        repostsCount: 2,
        durationMs: 90000,
      );

      final updated = track.copyWith(
        title: 'Updated',
        audioUrl: 'https://example.com/updated.mp3',
        likesCount: 10,
      );

      expect(updated.id, '1');
      expect(updated.title, 'Updated');
      expect(updated.artist, 'Artist');
      expect(updated.audioUrl, 'https://example.com/updated.mp3');
      expect(updated.artworkUrl, 'https://example.com/art.jpg');
      expect(updated.handle, 'artist');
      expect(updated.artistId, 'artist-1');
      expect(updated.likesCount, 10);
      expect(updated.repostsCount, 2);
      expect(updated.durationMs, 90000);
    });
  });
}
