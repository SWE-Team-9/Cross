import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class UpdateService {
  static const String _versionUrl =
      'https://raw.githubusercontent.com/SWE-Team-9/Cross/releases/version.json';

  static final Dio _dio = Dio();

  static Future<Map<String, dynamic>?> checkForUpdate() async {
     if (kDebugMode) return null;
    try {
      print('>>> [UpdateService] fetching version.json...');

      final response = await _dio.get(
        _versionUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          responseType: ResponseType.plain, // fix: get as raw string
        ),
      );

      print('>>> [UpdateService] status: ${response.statusCode}');
      if (response.statusCode != 200) return null;

      // fix: manually decode the raw string
      final data = jsonDecode(response.data as String) as Map<String, dynamic>;
      print('>>> [UpdateService] parsed data: $data');

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.split('+').first.trim();
      final latestVersion =
          (data['latest_version'] as String).split('+').first.trim();

      print(
          '>>> [UpdateService] current: $currentVersion | latest: $latestVersion');

      if (_isNewer(latestVersion, currentVersion)) {
        print('>>> [UpdateService] update available!');
        return data;
      }

      print('>>> [UpdateService] already up to date');
      return null;
    } catch (e) {
      print('>>> [UpdateService] error: $e');
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
