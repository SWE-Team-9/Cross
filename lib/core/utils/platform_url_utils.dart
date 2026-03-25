import 'dart:io' show Platform;

class PlatformUrlUtils {
  const PlatformUrlUtils._();

  static String? normalizeBackendUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return null;
    }

    if (Platform.isWindows) {
      return url.replaceFirst('10.0.2.2', '127.0.0.1');
    }

    return url;
  }
}
