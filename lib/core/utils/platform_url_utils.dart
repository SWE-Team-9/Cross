export 'color_extensions.dart';
import '../config/app_config.dart';

class PlatformUrlUtils {
  const PlatformUrlUtils._();

  static String? normalizeBackendUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (_isLocalHost(uri.host)) {
      final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
      return '${AppConfig.apiUrl}$path';
    }

    return url;
  }

  static bool _isLocalHost(String host) {
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '10.0.2.2' ||
        host.isEmpty;
  }

  static String getBaseUrl() => AppConfig.apiUrl;
}
