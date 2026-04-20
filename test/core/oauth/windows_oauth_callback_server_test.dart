import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/oauth/windows_oauth_callback_server.dart';

void main() {
  group('WindowsOAuthCallbackServer', () {
    test('returns callback uri and serves completion page', () async {
      final server = WindowsOAuthCallbackServer();
      final callbackFuture = server.waitForCallback(
        port: 18080,
        timeout: const Duration(seconds: 5),
      );

      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse('http://127.0.0.1:18080/callback?code=abc&state=xyz'),
      );
      final response = await request.close();
      final body = await response.transform(SystemEncoding().decoder).join();

      expect(response.statusCode, HttpStatus.ok);
      expect(body, contains('Authentication complete'));
      expect(body, contains('You can close this window'));

      final callbackUri = await callbackFuture;
      expect(callbackUri.path, '/callback');
      expect(callbackUri.queryParameters['code'], 'abc');
      expect(callbackUri.queryParameters['state'], 'xyz');

      client.close(force: true);
      await server.stop();
    });

    test('times out when no callback is received', () async {
      final server = WindowsOAuthCallbackServer();

      await expectLater(
        server.waitForCallback(
          port: 18081,
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('stop is safe when server was never started', () async {
      final server = WindowsOAuthCallbackServer();
      await expectLater(server.stop(), completes);
    });
  });
}
