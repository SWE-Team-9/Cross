import '../config/app_config.dart';

abstract class ApiConstants {
  static String get baseUrl => AppConfig.apiUrl;

  // ── Auth ────────────────────────────────────────────────────────────────
  static const String authBase = '/api/v1/auth';

  static const String login = '$authBase/login';
  static const String register = '$authBase/register';
  static const String logout = '$authBase/logout';
  static const String refreshToken = '$authBase/refresh';
  static const String verifyEmail = '$authBase/verify-email';
  static const String forgotPassword = '$authBase/forgot-password';
  static const String resetPassword = '$authBase/reset-password';
  static const String currentUser = '$authBase/me';
  static const String resendVerification = '$authBase/resend-verification';
  static const String emailChange = '$authBase/email/change';
  static const String confirmEmailChange = '$authBase/email/confirm-change';
  static const String sessions = '$authBase/sessions';

  // ── OAuth ───────────────────────────────────────────────────────────────
  static const String oauthBase = '/api/v1/oauth';
  static const String oauthAuthorize = '$oauthBase/authorize';
  static const String oauthToken = '$oauthBase/token';
  static const String oauthRevoke = '$oauthBase/revoke';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // ── Profiles ────────────────────────────────────────────────────────────
  static const String profilesBase = '/api/v1/profiles';
  static const String myProfile = '$profilesBase/me';
  static const String profileImages = '$profilesBase/me/images';
  static const String checkHandle = '$profilesBase/check-handle';
  static const String profileLinks = '$profilesBase/me/links';

  static String profileByHandlePath(String handle) => '$profilesBase/$handle';

  // ── Social graph ────────────────────────────────────────────────────────
  static const String socialBase = '/api/v1/social';

  static String followersPath(String userId) => '$socialBase/$userId/followers';
  static String followingPath(String userId) => '$socialBase/$userId/following';
  static String followUserPath(String userId) => '$socialBase/follow/$userId';
  static String blockUserPath(String userId) => '$socialBase/block/$userId';
  static const String blockedUsersPath = '$socialBase/blocked-users';
  static const String suggestedUsersPath = '$socialBase/suggestions';

  // ── Tracks ──────────────────────────────────────────────────────────────
  static const String tracks = '/api/v1/tracks';
  static const String users = '/api/v1/users';

  static String trackByIdPath(String trackId) => '$tracks/$trackId';
  static String trackStatusPath(String trackId) =>
      '${trackByIdPath(trackId)}/status';
  static String trackWaveformPath(String trackId) =>
      '${trackByIdPath(trackId)}/waveform';
  static String userTracksPath(String userId) => '$users/$userId/tracks';
  static String playerTrackSourcePath(String trackId) =>
      '/api/v1/player/tracks/$trackId/source';
  static String playerTrackPlayPath(String trackId) =>
      '/api/v1/player/tracks/$trackId/play';
  static const String listeningHistoryPath = '/api/v1/player/me/history';

  // ── Subscriptions / Premium ─────────────────────────────────────────────
  static const String subscriptionsBase = '/api/v1/subscriptions';
  static const String mySubscription = '$subscriptionsBase/me';
  static const String subscriptionPlans = '$subscriptionsBase/plans';
  static const String subscriptionInvoices = '$subscriptionsBase/invoices';
  static const String subscriptionCheckout = '$subscriptionsBase/checkout';
  static const String subscriptionSubscribe = '$subscriptionsBase/subscribe';
  static const String subscriptionPortal = '$subscriptionsBase/portal';
  static const String subscriptionResume = '$subscriptionsBase/resume';
  static const String subscriptionChangePlan = '$subscriptionsBase/change-plan';
  static const String subscriptionCancelPlanChange =
      '$subscriptionsBase/cancel-plan-change';
  static const String subscriptionCancel = '$subscriptionsBase/cancel';
  static String subscriptionOfflineTrackPath(String trackId) =>
      '$subscriptionsBase/offline/$trackId';

  static String subscriptionOfflineTrackStreamPath(String trackId) =>
      '${subscriptionOfflineTrackPath(trackId)}/stream';

  // ── Interactions ────────────────────────────────────────────────────────
  static const String interactionsBase = '/api/v1/interactions';
  static const String commentsBase = '$interactionsBase/comments';

  static String likeTrackPath(String trackId) =>
      '$interactionsBase/tracks/$trackId/like';

  static String repostTrackPath(String trackId) =>
      '$interactionsBase/tracks/$trackId/repost';

  static String trackInteractionStatusPath(String trackId) =>
      '$interactionsBase/tracks/$trackId/status';

  static String trackCommentsPath(String trackId) =>
      '$interactionsBase/tracks/$trackId/comments';

  static String commentByIdPath(String commentId) => '$commentsBase/$commentId';

  static String trackLikersPath(String trackId) =>
      '$interactionsBase/tracks/$trackId/likers';

  static String trackRepostersPath(String trackId) =>
      '$interactionsBase/tracks/$trackId/reposters';

  static const String myLikedTracks = '/api/v1/interactions/me/likes';
  static const String myRepostedTracks = '/api/v1/interactions/me/reposts';

  static String likePlaylistPath(String playlistId) =>
      '$playlistsBase/$playlistId/like';

  // ── Messaging ─────────────────────────────────────────────────────────────
  static const String messagingBase = '/api/v1/messages';
  static const String messagingConversationsPath =
      '$messagingBase/conversations';
  static const String messagingDirectConversationPath =
      '$messagingConversationsPath/direct';
  static const String messagingShareTrackPath = '$messagingBase/share/track';
  static const String messagingSharePlaylistPath =
      '$messagingBase/share/playlist';
  static const String messagingUnreadCountPath = '$messagingBase/unread-count';

  static String messagingConversationByIdPath(String conversationId) =>
      '$messagingConversationsPath/$conversationId';

  static String messagingConversationMetaPath(String conversationId) =>
      '${messagingConversationByIdPath(conversationId)}/meta';

  static String messagingMarkConversationReadPath(String conversationId) =>
      '${messagingConversationByIdPath(conversationId)}/read';

  static String messagingMarkConversationUnreadPath(String conversationId) =>
      '${messagingConversationByIdPath(conversationId)}/unread';

  static String messagingArchiveConversationPath(String conversationId) =>
      '${messagingConversationByIdPath(conversationId)}/archive';

  static String messagingUnarchiveConversationPath(String conversationId) =>
      '${messagingConversationByIdPath(conversationId)}/unarchive';

  static String messagingMessageByIdPath(String messageId) =>
      '$messagingBase/$messageId';
  // ── Playlists ───────────────────────────────────────────────────────────
  static const String playlistsBase = '/api/v1/playlists';
  static const String myPlaylists = '$playlistsBase/me';
  static const String myLikedPlaylists = '$playlistsBase/me/liked';
  static const String recentPlaylists = '$playlistsBase/recent';
  static const String topPlaylists = '$playlistsBase/top';

  static String playlistByIdPath(String playlistId) =>
      '$playlistsBase/$playlistId';

  static String playlistEditPath(String playlistId) =>
      '${playlistByIdPath(playlistId)}/edit';

  static String playlistCoverPath(String playlistId) =>
      '${playlistByIdPath(playlistId)}/cover';

  static String playlistTracksPath(String playlistId) =>
      '${playlistByIdPath(playlistId)}/tracks';

  static String removeTrackFromPlaylistPath(
          String playlistId, String trackId) =>
      '${playlistTracksPath(playlistId)}/$trackId';

  static String reorderPlaylistPath(String playlistId) =>
      '${playlistByIdPath(playlistId)}/reorder';

  static String resolveSecretPlaylistPath(String secretToken) =>
      '$playlistsBase/secret/$secretToken';

  static String playlistPlayPath(String playlistId) =>
      '${playlistByIdPath(playlistId)}/play';
  static String playlistEmbedPath(String playlistId) =>
      '${playlistByIdPath(playlistId)}/embed';

  // ── Feed ────────────────────────────────────────────────────────────────
  static const String feedBase = '/api/v1/feed';

  static const String activityFeed = feedBase;

  // ── Player Queue ─────────────────────────────────────────────────────────
  static const String playerBase = '/api/v1/player';

  static String trackPreviewPath(String trackId) =>
      '$playerBase/tracks/$trackId/preview';

  static const String queueLoad = '$playerBase/queue/load';
  static const String queueNext = '$playerBase/queue/next';
  static const String queuePrevious = '$playerBase/queue/previous';
  static const String queueCurrent = '$playerBase/queue';
  static const String queueJump = '$playerBase/queue/jump';

// ── Discovery ───────────────────────────────────────────────────────────
  static const String discoveryBase = '/api/v1/discovery';

  static const String globalSearch = '$discoveryBase/search';
  static const String trending = '$discoveryBase/trending';
  static const String resolve = '$discoveryBase/resolve';

  static String discoveryTrendingGenreTracksPath(String genreSlug) =>
      '$trending/genres/$genreSlug/tracks';
}
