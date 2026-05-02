import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_genre.dart';

void main() {
  group('trackGenreApiValue', () {
    test('maps genre slugs to backend genre names', () {
      const expectedNames = <String, String>{
        'electronic': 'Electronic',
        'hip-hop': 'Hip-Hop',
        'pop': 'Pop',
        'rock': 'Rock',
        'alternative': 'Alternative',
        'ambient': 'Ambient',
        'classical': 'Classical',
        'jazz': 'Jazz',
        'r-b-soul': 'R&B / Soul',
        'metal': 'Metal',
        'folk-singer-songwriter': 'Folk / Singer-Songwriter',
        'country': 'Country',
        'reggaeton': 'Reggaeton',
        'dancehall': 'Dancehall',
        'drum-bass': 'Drum & Bass',
        'house': 'House',
        'techno': 'Techno',
        'deep-house': 'Deep House',
        'trance': 'Trance',
        'lo-fi': 'Lo-Fi',
        'indie': 'Indie',
        'punk': 'Punk',
        'blues': 'Blues',
        'latin': 'Latin',
        'afrobeat': 'Afrobeat',
        'trap': 'Trap',
        'experimental': 'Experimental',
        'world': 'World',
        'gospel': 'Gospel',
        'spoken-word': 'Spoken Word',
        'quran': 'Quran',
        'sha3by': 'Sha3by',
        'islamic': 'Islamic',
      };

      for (final entry in expectedNames.entries) {
        expect(trackGenreApiValue(entry.key), entry.value);
      }
    });

    test('normalizes backend display names to slugs', () {
      expect(normalizeTrackGenreName('R&B / Soul'), 'r-b-soul');
      expect(
        normalizeTrackGenreName('Folk / Singer-Songwriter'),
        'folk-singer-songwriter',
      );
      expect(normalizeTrackGenreName('None'), kTrackGenreNone);
    });
  });
}
