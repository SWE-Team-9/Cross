// test/core/deep_links/deep_link_parser_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/deep_links/deep_link_destination.dart';
import 'package:soundcloud_clone/core/deep_links/deep_link_parser.dart';

void main() {
  group('DeepLinkParser', () {
    group('track links', () {
      test('parses valid track link', () {
        final uri = Uri.parse('soundclone://track/abc-123-uuid');
        final result = DeepLinkParser.parse(uri);
        expect(result, isA<TrackDeepLink>());
        expect((result as TrackDeepLink).trackId, 'abc-123-uuid');
      });

      test('returns invalid for track link with no ID', () {
        final uri = Uri.parse('soundclone://track/');
        final result = DeepLinkParser.parse(uri);
        expect(result, isA<InvalidDeepLink>());
      });
    });

    group('secret track links', () {
      test('parses valid secret track link', () {
        final uri =
            Uri.parse('soundclone://track/secret/V1StGXR8_Z5jdHi6B-myT-RQ');
        final result = DeepLinkParser.parse(uri);
        expect(result, isA<SecretTrackDeepLink>());
        expect(
          (result as SecretTrackDeepLink).secretToken,
          'V1StGXR8_Z5jdHi6B-myT-RQ',
        );
      });

      test('returns invalid for secret link with no token', () {
        final uri = Uri.parse('soundclone://track/secret/');
        final result = DeepLinkParser.parse(uri);
        expect(result, isA<InvalidDeepLink>());
      });
    });

    group('profile links', () {
      test('parses valid profile link', () {
        final uri = Uri.parse('soundclone://user/amrdiab');
        final result = DeepLinkParser.parse(uri);
        expect(result, isA<ProfileDeepLink>());
        expect((result as ProfileDeepLink).handle, 'amrdiab');
      });

      test('returns invalid for user link with no handle', () {
        final uri = Uri.parse('soundclone://user/');
        final result = DeepLinkParser.parse(uri);
        expect(result, isA<InvalidDeepLink>());
      });
    });

    group('playlist links', () {
      test('parses valid playlist link', () {
        final uri = Uri.parse('soundclone://playlist/pl-uuid-001');
        final result = DeepLinkParser.parse(uri);
        expect(result, isA<PlaylistDeepLink>());
        expect((result as PlaylistDeepLink).playlistId, 'pl-uuid-001');
      });

      test('parses valid secret playlist link', () {
        final uri = Uri.parse(
          'soundclone://playlist/secret/2e8b35f8-98d2-4f78-8899-b5fb688d809a',
        );
        final result = DeepLinkParser.parse(uri);
        expect(result, isA<SecretPlaylistDeepLink>());
        expect(
          (result as SecretPlaylistDeepLink).secretToken,
          '2e8b35f8-98d2-4f78-8899-b5fb688d809a',
        );
      });

      test('returns invalid for secret playlist link with no token', () {
        final uri = Uri.parse('soundclone://playlist/secret/');
        final result = DeepLinkParser.parse(uri);
        expect(result, isA<InvalidDeepLink>());
      });
    });

    group('search links', () {
      test('parses valid search link', () {
        final uri = Uri.parse('soundclone://search?q=amr+diab');
        final result = DeepLinkParser.parse(uri);
        expect(result, isA<SearchDeepLink>());
        expect((result as SearchDeepLink).query, 'amr diab');
      });

      test('returns invalid for search with no query', () {
        final uri = Uri.parse('soundclone://search?q=');
        final result = DeepLinkParser.parse(uri);
        expect(result, isA<InvalidDeepLink>());
      });
    });

    group('invalid links', () {
      test('rejects wrong scheme', () {
        final uri = Uri.parse('https://soundclone.app/track/abc');
        final result = DeepLinkParser.parse(uri);
        expect(result, isA<InvalidDeepLink>());
      });

      test('rejects unknown host', () {
        final uri = Uri.parse('soundclone://unknown/abc');
        final result = DeepLinkParser.parse(uri);
        expect(result, isA<InvalidDeepLink>());
      });
    });
  });
}
