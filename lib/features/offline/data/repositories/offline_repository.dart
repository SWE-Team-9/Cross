import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineRepository {
  final DioClient dio;

  OfflineRepository(this.dio);

  // ───────────── DOWNLOAD ─────────────
  Future<String> downloadTrack(String trackId) async {
    // STEP 1: entitlement check
    await dio.get('/api/v1/subscriptions/offline/$trackId');

    // STEP 2: download audio bytes
    final response = await dio.get(
      '/api/v1/subscriptions/offline/$trackId/stream',
      options: Options(responseType: ResponseType.bytes),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$trackId.mp3');

    await file.writeAsBytes(response.data);

    return file.path;
  }

  // ───────────── SAVE (PERSIST) ─────────────
  Future<void> saveDownloadedTracks(Map<String, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_tracks', jsonEncode(data));
  }

  // ───────────── LOAD (PERSIST) ─────────────
  Future<Map<String, String>> getDownloadedTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('offline_tracks');

    if (json == null) return {};

    return Map<String, String>.from(jsonDecode(json));
  }
}
