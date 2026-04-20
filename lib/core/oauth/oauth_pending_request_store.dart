import 'package:shared_preferences/shared_preferences.dart';

class OAuthPendingRequest {
  const OAuthPendingRequest({
    required this.state,
    required this.codeVerifier,
    required this.redirectUri,
  });

  final String state;
  final String codeVerifier;
  final String redirectUri;
}

class OAuthPendingRequestStore {
  OAuthPendingRequestStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _stateKey = 'oauth_pending_state';
  static const String _codeVerifierKey = 'oauth_pending_code_verifier';
  static const String _redirectUriKey = 'oauth_pending_redirect_uri';

  Future<void> save({
    required String state,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    await _prefs.setString(_stateKey, state);
    await _prefs.setString(_codeVerifierKey, codeVerifier);
    await _prefs.setString(_redirectUriKey, redirectUri);
  }

  OAuthPendingRequest? read() {
    final state = _prefs.getString(_stateKey);
    final codeVerifier = _prefs.getString(_codeVerifierKey);
    final redirectUri = _prefs.getString(_redirectUriKey);

    if (state == null || codeVerifier == null || redirectUri == null) {
      return null;
    }

    return OAuthPendingRequest(
      state: state,
      codeVerifier: codeVerifier,
      redirectUri: redirectUri,
    );
  }

  Future<void> clear() async {
    await _prefs.remove(_stateKey);
    await _prefs.remove(_codeVerifierKey);
    await _prefs.remove(_redirectUriKey);
  }
}
