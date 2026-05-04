import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum UpdateType { inApp, browser, store, unsupported }

class UpdateResult {
  final String downloadUrl;
  final UpdateType updateType;
  final Map<String, dynamic> data;

  const UpdateResult({
    required this.downloadUrl,
    required this.updateType,
    required this.data,
  });
}

class UpdateService {
  static const String _versionUrl =
      'https://raw.githubusercontent.com/SWE-Team-9/Cross/releases/version.json';

  static final Dio _dio = Dio();

  static String get _currentPlatform {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  static Future<UpdateResult?> checkForUpdate() async {
    try {
      print('>>> [UpdateService] platform: $_currentPlatform');

      final response = await _dio.get(
        _versionUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.data as String) as Map<String, dynamic>;

      // get platform-specific config
      final platforms = data['platforms'] as Map<String, dynamic>?;
      final platformData =
          platforms?[_currentPlatform] as Map<String, dynamic>?;

      if (platformData == null) {
        print('>>> [UpdateService] no update config for $_currentPlatform');
        return null;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.split('+').first.trim();
      final latestVersion =
          (data['latest_version'] as String).split('+').first.trim();

      print(
          '>>> [UpdateService] current: $currentVersion | latest: $latestVersion');

      if (!_isNewer(latestVersion, currentVersion)) {
        print('>>> [UpdateService] already up to date');
        return null;
      }

      final updateTypeStr = (platformData['update_type'] ?? '') as String;
      final updateType = switch (updateTypeStr) {
        'in_app' => UpdateType.inApp,
        'browser' => UpdateType.browser,
        'store' => UpdateType.store,
        _ => UpdateType.unsupported,
      };

      if (updateType == UpdateType.unsupported) return null;

      print('>>> [UpdateService] update available via $updateTypeStr');

      return UpdateResult(
        downloadUrl: platformData['download_url'] as String,
        updateType: updateType,
        data: data,
      );
    } catch (e, st) {
      print('>>> [UpdateService] error: $e');
      print(st);
      return null;
    }
  }

  static bool isMandatoryUpdate(
      Map<String, dynamic> data, String currentVersion) {
    final minVersion =
        (data['min_required_version'] as String).split('+').first.trim();
    final current = currentVersion.split('+').first.trim();
    return _isNewer(minVersion, current);
  }

  static bool _isNewer(String latest, String current) {
    try {
      final l = latest
          .split('-')
          .first
          .split('.')
          .map((e) => int.parse(e.trim()))
          .toList();
      final c = current
          .split('-')
          .first
          .split('.')
          .map((e) => int.parse(e.trim()))
          .toList();

      while (l.length < 3) l.add(0);
      while (c.length < 3) c.add(0);

      for (int i = 0; i < 3; i++) {
        if (l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
      return false;
    } catch (e) {
      print('>>> [UpdateService] _isNewer parse error: $e');
      return false;
    }
  }
}
