import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static const String _versionUrl =
      'https://raw.githubusercontent.com/SWE-Team-9/Cross/releases/version.json';

  static final Dio _dio = Dio(); // optional: reuse instance

  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final response = await _dio.get(
        _versionUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.statusCode != 200) return null;

      final data = response.data as Map<String, dynamic>;
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final latestVersion = data['latest_version'] as String;

      if (_isNewer(latestVersion, currentVersion)) {
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static bool isMandatoryUpdate(Map<String, dynamic> data, String currentVersion) {
    final minVersion = data['min_required_version'] as String;
    return _isNewer(minVersion, currentVersion);
  }

  static bool _isNewer(String latest, String current) {
    final l = latest.split('.').map(int.parse).toList();
    final c = current.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }
}