// // coverage:ignore-file
// // ─────────────────────────────────────────────────────────────────────────────
// //  feed_mock_data_source.dart  —  Mock Data Source
// //  Used while backend is not ready.
// //  Every object shape is identical to the real API response.
// //  To switch to real API: change FeedRepositoryImpl to use
// //  FeedRemoteDataSourceImpl instead of FeedMockDataSource.
// // ─────────────────────────────────────────────────────────────────────────────

// import '../dto/feed_item_model.dart';
// import '../datasources/feed_remote_data_sources.dart';

// class FeedMockDataSource implements FeedRemoteDataSource {
//   static const int _delay = 800; // ms — simulates network latency

//   // ─── Real stream URLs (soundhelix) ───────────────────────────────────────

//   static const Map<String, String> _streamUrls = {
//     'trk_001': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
//     'trk_002': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
//     'trk_003': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
//     'trk_004': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
//     'trk_005': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
//     'trk_006': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
//     'trk_007': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
//     'trk_008': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
//     'trk_009': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
//     'trk_010': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
//     'trk_011': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3',
//     'trk_012': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-12.mp3',
//     // Discover tab
//     'trk_101': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
//     'trk_102': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
//     'trk_103': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
//     'trk_104': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
//     'trk_105': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
//     'trk_106': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
//   };

//   // ─── Mock items ──────────────────────────────────────────────────────────

//   static final List<Map<String, dynamic>> _followingRaw = [
//     _item('act_001', 'posted a track', '15 days ago',
//         actor: _actor('usr_001', 'che', 'che-music', verified: true),
//         track: _track('trk_001', 'Tattoos', 'tattoos', 143000, 'Alternative',
//             likes: 21600, comments: 1400, reposts: 870, plays: 98400)),
//     _item('act_002', 'posted a track', '2 hours ago',
//         actor: _actor('usr_002', 'KayArchon', 'kayarchon'),
//         track: _track('trk_002', 'she goes by.', 'she-goes-by', 191000, 'Indie',
//             likes: 4200, comments: 380, reposts: 210, plays: 18700)),
//     _item('act_003', 'reposted a track', '5 hours ago',
//         actor: _actor('usr_003', 'soundwave', 'soundwave', verified: true),
//         track: _track(
//             'trk_003', 'Midnight Run', 'midnight-run', 285000, 'Electronic',
//             likes: 8900, comments: 720, reposts: 1100, plays: 44000)),
//     _item('act_004', 'posted a track', '1 day ago',
//         actor: _actor('usr_004', 'nova.beats', 'nova-beats'),
//         track: _track('trk_004', 'Desert Storm', 'desert-storm', 208000, 'Trap',
//             likes: 2100, comments: 190, reposts: 95, plays: 9800)),
//     _item('act_005', 'liked a track', '2 days ago',
//         actor: _actor('usr_005', 'elara', 'elara', verified: true),
//         track: _track('trk_005', 'Glass City', 'glass-city', 302000, 'Ambient',
//             likes: 15300, comments: 1100, reposts: 2200, plays: 71000)),
//     _item('act_006', 'posted a track', '3 days ago',
//         actor: _actor('usr_006', 'drift.wav', 'drift-wav'),
//         track: _track('trk_006', 'Echoes', 'echoes', 235000, 'Lo-Fi',
//             likes: 6700, comments: 540, reposts: 780, plays: 32000)),
//     _item('act_007', 'posted a track', '4 days ago',
//         actor: _actor('usr_007', 'milo_r', 'milo-r'),
//         track: _track(
//             'trk_007', 'Neon Signs', 'neon-signs', 178000, 'Synthwave',
//             likes: 3400, comments: 290, reposts: 310, plays: 15600)),
//     _item('act_008', 'reposted a track', '5 days ago',
//         actor: _actor('usr_008', 'aura.music', 'aura-music', verified: true),
//         track: _track('trk_008', 'Solstice', 'solstice', 370000, 'Electronic',
//             likes: 22100, comments: 1800, reposts: 3400, plays: 104000)),
//     _item('act_009', 'posted a track', '6 days ago',
//         actor: _actor('usr_009', 'prism', 'prism', verified: true),
//         track: _track(
//             'trk_009', 'Refraction', 'refraction', 258000, 'Electronic',
//             likes: 11200, comments: 890, reposts: 1560, plays: 54000)),
//     _item('act_010', 'posted a track', '7 days ago',
//         actor: _actor('usr_010', 'lowkey.lo', 'lowkey-lo'),
//         track: _track('trk_010', 'Paperweight', 'paperweight', 182000, 'Lo-Fi',
//             likes: 1200, comments: 88, reposts: 43, plays: 5600)),
//     _item('act_011', 'posted a track', '8 days ago',
//         actor: _actor('usr_011', 'marz', 'marz'),
//         track: _track('trk_011', 'Red Planet', 'red-planet', 330000, 'Hip-Hop',
//             likes: 5600, comments: 420, reposts: 610, plays: 27000)),
//     _item('act_012', 'reposted a track', '10 days ago',
//         actor: _actor('usr_012', 'zephyr', 'zephyr', verified: true),
//         track: _track('trk_012', 'Windfall', 'windfall', 227000, 'Ambient',
//             likes: 9800, comments: 760, reposts: 1230, plays: 47000)),
//   ];

//   static final List<Map<String, dynamic>> _discoverRaw = [
//     _item('disc_001', 'trending worldwide', 'now',
//         actor: _actor('usr_101', 'aurora', 'aurora-official', verified: true),
//         track: _track('trk_101', 'Aurora Borealis', 'aurora-borealis', 260000,
//             'Electronic',
//             likes: 54200, comments: 3200, reposts: 8900, plays: 280000)),
//     _item('disc_002', '#1 in Electronic', 'today',
//         actor: _actor('usr_102', 'volt', 'volt-music', verified: true),
//         track: _track('trk_102', 'Voltage', 'voltage', 224000, 'Electronic',
//             likes: 31700, comments: 2100, reposts: 5400, plays: 160000)),
//     _item('disc_003', 'new release · Hip-Hop', '12 hours ago',
//         actor: _actor('usr_103', 'cloudy', 'cloudy'),
//         track: _track('trk_103', 'Cloud Nine', 'cloud-nine', 196000, 'Hip-Hop',
//             likes: 1200, comments: 88, reposts: 43, plays: 6200)),
//     _item('disc_004', 'trending in Egypt', '1 day ago',
//         actor: _actor('usr_104', 'Ahmed Hassan', 'ahmed-hassan-beats',
//             verified: true),
//         track: _track('trk_104', 'Layali', 'layali', 232000, 'Oriental',
//             likes: 18400, comments: 1340, reposts: 3100, plays: 92000)),
//     _item('disc_005', 'staff pick', '2 days ago',
//         actor: _actor('usr_105', 'nova.beats', 'nova-beats'),
//         track: _track('trk_105', 'Weightless', 'weightless', 318000, 'Ambient',
//             likes: 7800, comments: 620, reposts: 940, plays: 38000)),
//     _item('disc_006', 'new release · Lo-Fi', '3 days ago',
//         actor: _actor('usr_106', 'drift.wav', 'drift-wav'),
//         track: _track('trk_106', 'Still Water', 'still-water', 244000, 'Lo-Fi',
//             likes: 4300, comments: 310, reposts: 480, plays: 21000)),
//   ];

//   // ─── Builder helpers ─────────────────────────────────────────────────────

//   static Map<String, dynamic> _actor(
//     String userId,
//     String displayName,
//     String handle, {
//     bool verified = false,
//   }) =>
//       {
//         'userId': userId,
//         'displayName': displayName,
//         'handle': handle,
//         'avatarUrl': null,
//         'verified': verified,
//       };

//   static Map<String, dynamic> _track(
//     String trackId,
//     String title,
//     String slug,
//     int durationMs,
//     String genre, {
//     required int likes,
//     required int comments,
//     required int reposts,
//     required int plays,
//   }) =>
//       {
//         'trackId': trackId,
//         'title': title,
//         'slug': slug,
//         'durationMs': durationMs,
//         'status': 'FINISHED',
//         'visibility': 'PUBLIC',
//         'coverArtUrl': null,
//         'genre': genre,
//         'waveformData': null,
//         'artist': {
//           'id': 'usr_artist',
//           'displayName': title,
//           'handle': slug,
//           'avatarUrl': null,
//           'verified': false,
//         },
//         'stats': {
//           'likesCount': likes,
//           'commentsCount': comments,
//           'repostsCount': reposts,
//           'playsCount': plays,
//         },
//         'userState': {
//           'liked': false,
//           'reposted': false,
//           'inLibrary': false,
//         },
//       };

//   static Map<String, dynamic> _item(
//     String activityId,
//     String action,
//     String timeAgo, {
//     required Map<String, dynamic> actor,
//     required Map<String, dynamic> track,
//   }) =>
//       {
//         'activityId': activityId,
//         'action': action,
//         'timeAgo': timeAgo,
//         'actor': actor,
//         'track': track,
//       };

//   // ─── Interface implementation ─────────────────────────────────────────────

//   @override
//   Future<FeedPageModel> getFeed(
//       {required String tab, required int page}) async {
//     await Future.delayed(const Duration(milliseconds: _delay));

//     final source = tab == 'following' ? _followingRaw : _discoverRaw;
//     const pageSize = kPageSize;
//     final start = (page - 1) * pageSize;
//     final end = (start + pageSize).clamp(0, source.length);
//     final slice = source.sublist(start.clamp(0, source.length), end);

//     final wrapped = {
//       'tracks': slice,
//       'page': page,
//       'totalTracks': source.length,
//     };

//     return FeedPageModel.fromJson(wrapped, pageSize);
//   }

//   @override
//   Future<Map<String, dynamic>> toggleLike({
//     required String trackId,
//     required bool currentlyLiked,
//   }) async {
//     await Future.delayed(const Duration(milliseconds: 200));
//     return {
//       'message': currentlyLiked
//           ? 'Track unliked successfully'
//           : 'Track liked successfully',
//       'trackId': trackId,
//       'likesCount': 0,
//       'liked': !currentlyLiked,
//     };
//   }

//   @override
//   Future<Map<String, dynamic>> toggleRepost({
//     required String trackId,
//     required bool currentlyReposted,
//   }) async {
//     await Future.delayed(const Duration(milliseconds: 200));
//     return {
//       'message': currentlyReposted
//           ? 'Repost removed successfully'
//           : 'Track reposted successfully',
//       'trackId': trackId,
//       'repostsCount': 0,
//       'reposted': !currentlyReposted,
//     };
//   }

//   @override
//   Future<Map<String, dynamic>> getTrackSource(String trackId) async {
//     await Future.delayed(const Duration(milliseconds: 300));

//     final url = _streamUrls[trackId] ??
//         'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

//     return {
//       'trackId': trackId,
//       'streamUrl': url,
//       'accessState': 'PLAYABLE',
//       'expiresAt':
//           DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
//     };
//   }

//   @override
//   Future<void> recordPlay(String trackId) async {
//     await Future.delayed(const Duration(milliseconds: 150));
//     // fire and forget in mock
//   }
// }
