// coverage:ignore-file
// ─────────────────────────────────────────────────────────────────────────────
//  feed_remote_data_source.dart  —  Real HTTP Calls
//
//  Endpoints used:
//    Module 4 → GET  /api/v1/users/{userId}/tracks?page=&limit=
//    Module 3 → GET  /api/v1/social/suggestions?limit=
//    Module 5 → GET  /api/v1/player/tracks/{trackId}/source
//               POST /api/v1/player/tracks/{trackId}/play
//    Module 6 → POST   /api/v1/interactions/tracks/{trackId}/like
//               DELETE /api/v1/interactions/tracks/{trackId}/like
//               POST   /api/v1/interactions/tracks/{trackId}/repost
//               DELETE /api/v1/interactions/tracks/{trackId}/repost
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dto/feed_item_model.dart';

const int kPageSize = 20;

abstract class FeedRemoteDataSource {
  Future<FeedPageModel> getFeed({required String tab, required int page});
  Future<Map<String, dynamic>> toggleLike(
      {required String trackId, required bool currentlyLiked});
  Future<Map<String, dynamic>> toggleRepost(
      {required String trackId, required bool currentlyReposted});
  Future<Map<String, dynamic>> getTrackSource(String trackId);
  Future<void> recordPlay(String trackId);
}

// ─────────────────────────────────────────────────────────────────────────────

class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  final http.Client client;
  final String baseUrl;
  final String? authToken; // pass from AuthRepository / SecureStorage

  FeedRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
    this.authToken,
  });

  // ─── Shared ──────────────────────────────────────────────────────────────

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await client.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    _checkStatus(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _post(String path,
      [Map<String, dynamic>? body]) async {
    final res = await client.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    );
    _checkStatus(res);
    if (res.statusCode == 204) return {};
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final res = await client.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers,
    );
    _checkStatus(res);
    if (res.statusCode == 204) return {};
    return json.decode(res.body) as Map<String, dynamic>;
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode >= 400) {
      final body = json.decode(res.body) as Map<String, dynamic>?;
      throw Exception(body?['message'] ?? 'HTTP ${res.statusCode}');
    }
  }

  // ─── Feed ────────────────────────────────────────────────────────────────

  @override
  Future<FeedPageModel> getFeed(
      {required String tab, required int page}) async {
    if (tab == 'following') {
      // Module 4: GET /api/v1/users/{userId}/tracks?page=&limit=
      // 'me' is resolved by the backend from the auth token
      final data =
          await _get('/api/v1/users/me/tracks?page=$page&limit=$kPageSize');
      return FeedPageModel.fromJson(data, kPageSize);
    } else {
      // Module 3: GET /api/v1/social/suggestions?limit=
      final data = await _get('/api/v1/social/suggestions?limit=$kPageSize');
      // suggestions returns a flat list, wrap it in page shape
      return FeedPageModel.fromJson({
        'tracks': data['suggestions'] ?? [],
        'page': 1,
        'totalTracks': (data['suggestions'] as List?)?.length ?? 0,
      }, kPageSize);
    }
  }

  // ─── Like ────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> toggleLike({
    required String trackId,
    required bool currentlyLiked,
  }) async {
    if (currentlyLiked) {
      // Module 6: DELETE /api/v1/interactions/tracks/{trackId}/like
      // Response: { message, trackId, likesCount, liked: false }
      return _delete('/api/v1/interactions/tracks/$trackId/like');
    } else {
      // Module 6: POST /api/v1/interactions/tracks/{trackId}/like
      // Response: { message, trackId, likesCount, liked: true }
      return _post('/api/v1/interactions/tracks/$trackId/like');
    }
  }

  // ─── Repost ──────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> toggleRepost({
    required String trackId,
    required bool currentlyReposted,
  }) async {
    if (currentlyReposted) {
      // Module 6: DELETE /api/v1/interactions/tracks/{trackId}/repost
      // Response: { message, trackId, reposted: false }
      return _delete('/api/v1/interactions/tracks/$trackId/repost');
    } else {
      // Module 6: POST /api/v1/interactions/tracks/{trackId}/repost
      // Response: { message, trackId, repostsCount, reposted: true }
      return _post('/api/v1/interactions/tracks/$trackId/repost');
    }
  }

  // ─── Playback ────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getTrackSource(String trackId) async {
    // Module 5: GET /api/v1/player/tracks/{trackId}/source
    // Response: { trackId, streamUrl, accessState, expiresAt }
    // Errors: 403 blocked | 404 not found | 409 still processing
    return _get('/api/v1/player/tracks/$trackId/source');
  }

  @override
  Future<void> recordPlay(String trackId) async {
    // Module 5: POST /api/v1/player/tracks/{trackId}/play
    // Response: { message, trackId, playCount }
    await _post('/api/v1/player/tracks/$trackId/play');
  }
}
