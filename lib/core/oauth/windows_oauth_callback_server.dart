import 'dart:async';
import 'dart:io';

class WindowsOAuthCallbackServer {
  HttpServer? _server;

  Future<Uri> waitForCallback({
    int port = 8080,
    Duration timeout = const Duration(minutes: 2),
  }) async {
    await stop();

    final completer = Completer<Uri>();
    final timer = Timer(timeout, () async {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Timed out waiting for OAuth callback.'),
        );
      }
      await stop();
    });

    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
      shared: false,
    );

    _server!.listen(
      (request) async {
        final callbackUri =
            Uri.parse('http://127.0.0.1:$port${request.uri.toString()}');

        request.response.headers.contentType = ContentType.html;
        request.response.write('''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Authentication complete</title>
    <style>
      body {
        font-family: Arial, sans-serif;
        background: #111;
        color: #fff;
        display: flex;
        align-items: center;
        justify-content: center;
        height: 100vh;
        margin: 0;
      }
      .card {
        background: #1d1d1f;
        border-radius: 16px;
        padding: 24px 28px;
        text-align: center;
        box-shadow: 0 10px 30px rgba(0,0,0,0.35);
      }
      h1 { margin: 0 0 12px; font-size: 22px; }
      p { margin: 0; color: #c7c7cc; }
    </style>
  </head>
  <body>
    <div class="card">
      <h1>Authentication complete</h1>
      <p>You can close this window and return to the app.</p>
    </div>
  </body>
</html>
''');
        await request.response.close();

        if (!completer.isCompleted) {
          completer.complete(callbackUri);
        }

        timer.cancel();
        await stop();
      },
      onError: (Object error) async {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
        timer.cancel();
        await stop();
      },
      cancelOnError: true,
    );

    return completer.future;
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    if (server != null) {
      await server.close(force: true);
    }
  }
}