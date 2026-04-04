// import 'dart:io' show Platform;

// class PlatformUrlUtils {
//   const PlatformUrlUtils._();

//   static String? normalizeBackendUrl(String? url) {
//     if (url == null || url.trim().isEmpty) {
//       return null;
//     }

//     if (Platform.isWindows) {
//       return url.replaceFirst('10.0.2.2', '127.0.0.1');
//     }

//     return url;
//   }
// }

//////////////////////////////////////////////
///
// debugging code:
//
//////////////////////////////////////////////
// import 'dart:io' show Platform;

// class PlatformUrlUtils {
//   const PlatformUrlUtils._();

//   static String? normalizeBackendUrl(String? url) {
//     if (url == null || url.trim().isEmpty) {
//       print('🔍 DEBUG normalizeBackendUrl: URL is null or empty');
//       return null;
//     }

//     print('🔍 DEBUG normalizeBackendUrl - Input: $url');
//     print('🔍 DEBUG normalizeBackendUrl - Platform: ${Platform.operatingSystem}');

//     String normalizedUrl = url;

//     // Handle Android emulator
//     if (Platform.isAndroid) {
//       // Replace localhost/127.0.0.1 with 10.0.2.2 and fix port
//       if (url.contains('localhost:3000') || url.contains('127.0.0.1:3000')) {
//         normalizedUrl = url
//             .replaceAll('localhost:3000', '10.0.2.2:3006')
//             .replaceAll('127.0.0.1:3000', '10.0.2.2:3006');
//         print('🔍 DEBUG normalizeBackendUrl - Android converted: $normalizedUrl');
//       }
//       // Handle if URL already has 10.0.2.2 but wrong port
//       else if (url.contains('10.0.2.2:3000')) {
//         normalizedUrl = url.replaceAll(':3000', ':3006');
//         print('🔍 DEBUG normalizeBackendUrl - Android port fix: $normalizedUrl');
//       }
//       // Handle localhost without port or with port 3006
//       else if (url.contains('localhost') && !url.contains('3000')) {
//         normalizedUrl = url.replaceAll('localhost', '10.0.2.2');
//         print('🔍 DEBUG normalizeBackendUrl - Android localhost fix: $normalizedUrl');
//       }
//     }
//     // Handle iOS simulator
//     else if (Platform.isIOS) {
//       if (url.contains('localhost:3000')) {
//         normalizedUrl = url.replaceAll(':3000', ':3006');
//         print('🔍 DEBUG normalizeBackendUrl - iOS port fix: $normalizedUrl');
//       } else if (url.contains('10.0.2.2')) {
//         normalizedUrl = url.replaceFirst('10.0.2.2', 'localhost');
//         print('🔍 DEBUG normalizeBackendUrl - iOS converted: $normalizedUrl');
//       }
//     }
//     // Handle Windows
//     else if (Platform.isWindows) {
//       if (url.contains('10.0.2.2')) {
//         normalizedUrl = url.replaceFirst('10.0.2.2', '127.0.0.1');
//         print('🔍 DEBUG normalizeBackendUrl - Windows converted: $normalizedUrl');
//       }
//       // Fix port if needed
//       if (normalizedUrl.contains(':3000')) {
//         normalizedUrl = normalizedUrl.replaceAll(':3000', ':3006');
//         print('🔍 DEBUG normalizeBackendUrl - Windows port fix: $normalizedUrl');
//       }
//       if (normalizedUrl.contains('localhost:3006')) {
//         normalizedUrl = normalizedUrl.replaceAll('localhost:3006', '127.0.0.1:3006');
//         print('🔍 DEBUG normalizeBackendUrl - Windows localhost fix: $normalizedUrl');
//       }
//     }
//     // Handle Linux and macOS
//     else if (Platform.isLinux || Platform.isMacOS) {
//       if (url.contains('10.0.2.2')) {
//         normalizedUrl = url.replaceFirst('10.0.2.2', '127.0.0.1');
//         print('🔍 DEBUG normalizeBackendUrl - Desktop converted: $normalizedUrl');
//       }
//       if (normalizedUrl.contains(':3000')) {
//         normalizedUrl = normalizedUrl.replaceAll(':3000', ':3006');
//         print('🔍 DEBUG normalizeBackendUrl - Desktop port fix: $normalizedUrl');
//       }
//       if (normalizedUrl.contains('localhost:3006')) {
//         normalizedUrl = normalizedUrl.replaceAll('localhost:3006', '127.0.0.1:3006');
//         print('🔍 DEBUG normalizeBackendUrl - Desktop localhost fix: $normalizedUrl');
//       }
//     }

//     print('🔍 DEBUG normalizeBackendUrl - Final output: $normalizedUrl');
//     return normalizedUrl;
//   }

//   static String getBaseUrl() {
//     if (Platform.isAndroid) {
//       return 'http://10.0.2.2:3006';
//     } else if (Platform.isIOS) {
//       return 'http://localhost:3006';
//     } else {
//       return 'http://127.0.0.1:3006';
//     }
//   }
// }
////////////////////////////////////////////////////////////////////
///  Third code :
///
///
//////////////////////////////////////////////////////////////////////
import '../config/app_config.dart';

class PlatformUrlUtils {
  const PlatformUrlUtils._();

  static String? normalizeBackendUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // If URL has a corrupted/local host, extract path and rebuild with correct base
    if (_isLocalHost(uri.host)) {
      return '${AppConfig.apiUrl}${uri.path}';
    }

    // URL already has a real host (e.g. iqa3.tech) — return as-is
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