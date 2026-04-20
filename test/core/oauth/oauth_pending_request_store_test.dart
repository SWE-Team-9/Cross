import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundcloud_clone/core/oauth/oauth_pending_request_store.dart';

void main() {
  group('OAuthPendingRequestStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('save and read round trip works', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = OAuthPendingRequestStore(prefs);

      await store.save(
        state: 'state-1',
        codeVerifier: 'verifier-1',
        redirectUri: 'soundcloud://callback',
      );

      final pending = store.read();

      expect(pending, isNotNull);
      expect(pending!.state, 'state-1');
      expect(pending.codeVerifier, 'verifier-1');
      expect(pending.redirectUri, 'soundcloud://callback');
    });

    test('read returns null when request is incomplete', () async {
      SharedPreferences.setMockInitialValues({
        'oauth_pending_state': 'state-1',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = OAuthPendingRequestStore(prefs);

      expect(store.read(), isNull);
    });

    test('clear removes stored request', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = OAuthPendingRequestStore(prefs);

      await store.save(
        state: 'state-1',
        codeVerifier: 'verifier-1',
        redirectUri: 'soundcloud://callback',
      );
      await store.clear();

      expect(store.read(), isNull);
    });
  });
}
