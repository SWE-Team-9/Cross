import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/oauth/pkce_utils.dart';

void main() {
  group('PkceUtils', () {
    final allowed = RegExp(r'^[A-Za-z0-9\-\._~]+$');

    test('generateState returns expected length and charset', () {
      final state = PkceUtils.generateState(32);

      expect(state, hasLength(32));
      expect(allowed.hasMatch(state), isTrue);
    });

    test('generateCodeVerifier returns expected length and charset', () {
      final verifier = PkceUtils.generateCodeVerifier(64);

      expect(verifier, hasLength(64));
      expect(allowed.hasMatch(verifier), isTrue);
    });

    test('generateCodeChallenge is deterministic and base64url encoded', () {
      final challenge = PkceUtils.generateCodeChallenge('test-verifier');

      expect(challenge, 'JBbiqONGWPaAmwXk_8bT6UnlPfrn65D32eZlJS-zGG0');
      expect(challenge.contains('='), isFalse);
    });
  });
}
