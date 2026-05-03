import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/network/api_constants.dart';
import 'package:soundcloud_clone/features/messaging/data/datasources/messaging_socket_data_source.dart';


void main() {
  late Directory tempDir;
  late PersistCookieJar cookieJar;
  late MessagingSocketDataSourceImpl dataSource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('messaging_socket_test_');
    cookieJar = PersistCookieJar(
      storage: FileStorage(tempDir.path),
    );
    dataSource = MessagingSocketDataSourceImpl(
      cookieJar: cookieJar,
    );
  });

  tearDown(() async {
    await dataSource.dispose();

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MessagingSocketDataSourceImpl', () {
    test('starts disconnected', () {
      expect(dataSource.isConnected, isFalse);
    });

    test('eventsStream is broadcast', () {
      expect(dataSource.eventsStream.isBroadcast, isTrue);
    });

    test('allows multiple listeners on eventsStream', () async {
      final subscription1 = dataSource.eventsStream.listen((_) {});
      final subscription2 = dataSource.eventsStream.listen((_) {});

      await subscription1.cancel();
      await subscription2.cancel();

      expect(dataSource.eventsStream.isBroadcast, isTrue);
    });

    test('disconnect is safe before connect', () async {
      await dataSource.disconnect();

      expect(dataSource.isConnected, isFalse);
    });

    test('connect configures socket with persisted cookies', () async {
      await cookieJar.saveFromResponse(
        Uri.parse(ApiConstants.baseUrl),
        <Cookie>[Cookie('accessToken', 'token-1')],
      );

      await dataSource.connect();

      expect(dataSource.eventsStream.isBroadcast, isTrue);

      await dataSource.disconnect();

      expect(dataSource.isConnected, isFalse);
    });

    test('disconnect can be called multiple times safely', () async {
      await dataSource.disconnect();
      await dataSource.disconnect();

      expect(dataSource.isConnected, isFalse);
    });

    test('dispose is safe and keeps datasource disconnected', () async {
      await dataSource.dispose();

      expect(dataSource.isConnected, isFalse);
    });
  });
}
