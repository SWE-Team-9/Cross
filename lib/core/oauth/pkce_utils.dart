import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

abstract final class PkceUtils {
  static final Random _random = Random.secure();

  static const String _allowedChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  static String generateState([int length = 32]) {
    return _randomString(length);
  }

  static String generateCodeVerifier([int length = 64]) {
    return _randomString(length);
  }

  static String generateCodeChallenge(String codeVerifier) {
    final bytes = ascii.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static String _randomString(int length) {
    return List.generate(
      length,
      (_) => _allowedChars[_random.nextInt(_allowedChars.length)],
    ).join();
  }
}