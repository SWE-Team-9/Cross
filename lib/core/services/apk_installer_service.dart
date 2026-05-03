import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ApkInstallerService {
  static final Dio _dio = Dio();

  /// Downloads APK and triggers install prompt.
  /// [onProgress] returns 0.0 to 1.0
  static Future<void> downloadAndInstall({
    required String downloadUrl,
    required void Function(double progress) onProgress,
    required void Function(String error) onError,
  }) async {
    try {
      // 1. request install permission (Android 8+)
      final installPermission =
          await Permission.requestInstallPackages.request();
      if (!installPermission.isGranted) {
        onError('Please allow installing from unknown sources in settings.');
        await openAppSettings();
        return;
      }

      // 2. get temp directory
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/update.apk';

      // 3. delete old APK if exists
      final file = File(savePath);
      if (await file.exists()) await file.delete();

      // 4. download with progress
      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      // 5. trigger install
      final result = await OpenFilex.open(
        savePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        onError('Could not open installer: ${result.message}');
      }
    } on DioException catch (e) {
      onError('Download failed: ${e.message}');
    } catch (e) {
      onError('Unexpected error: $e');
    }
  }
}
