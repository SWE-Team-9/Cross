import '../config/app_config.dart';
import 'deep_link_destination.dart';

abstract final class DeepLinkParser {
  static const String _customScheme = 'iqa3';
  static const String _legacyScheme = 'soundclone';
  static final String _httpsHost = Uri.parse(AppConfig.apiUrl).host;

  static DeepLinkDestination parse(Uri uri) {
    if (uri.scheme == 'https' && uri.host == _httpsHost) {
      return _parseHttpsPath(uri);
    }

    if (uri.scheme == _customScheme || uri.scheme == _legacyScheme) {
      return _parseCustomScheme(uri);
    }

    return InvalidDeepLink(reason: 'Unknown scheme: ${uri.scheme}');
  }

  static DeepLinkDestination _parseHttpsPath(Uri uri) {
    final segments = uri.pathSegments;

    if (segments.isEmpty) {
      return const InvalidDeepLink(reason: 'Empty path');
    }

    switch (segments.first) {
      case 'track':
        return _parseTrack(segments.skip(1).toList());

      case 'playlist':
        return _parsePlaylist(segments.skip(1).toList());

      case 'share':
        return _parseSharePath(segments.skip(1).toList());

      case 'search':
        return _parseSearch(uri.queryParameters);

      case 'user':
      case 'profile':
        return _parseUser(segments.skip(1).toList());

      case 'reset-password':
      case 'verify-email':
      case 'auth':
        return InvalidDeepLink(
          reason: 'Web-only route — not handled by app: ${uri.path}',
        );

      default:
        return ResolvableResourceDeepLink(url: uri.toString());
    }
  }

  static DeepLinkDestination _parseCustomScheme(Uri uri) {
    final host = uri.host;
    final segments = uri.pathSegments;

    switch (host) {
      case 'track':
        return _parseTrack(segments);

      case 'user':
      case 'profile':
        return _parseUser(segments);

      case 'playlist':
        return _parsePlaylist(segments);

      case 'search':
        return _parseSearch(uri.queryParameters);

      case 'resolve':
        return _parseResolvableUri(uri);

      case 'billing':
        return _parseBilling(segments, uri.queryParameters);

      case 'checkout':
        return _parseCheckout(segments, uri.queryParameters);

      case 'oauth':
        return _parseOAuth(segments, uri.queryParameters);

      default:
        return InvalidDeepLink(reason: 'Unknown host: $host');
    }
  }

  static DeepLinkDestination _parseSharePath(List<String> segments) {
    if (segments.isEmpty) {
      return const InvalidDeepLink(reason: 'Share path missing type');
    }
    switch (segments.first) {
      case 'track':
        return _parseTrack(segments.skip(1).toList());
      case 'playlist':
        return _parsePlaylist(segments.skip(1).toList());
      default:
        return InvalidDeepLink(
          reason: 'Unknown share type: ${segments.first}',
        );
    }
  }

  static DeepLinkDestination _parseTrack(List<String> segments) {
    if (segments.isEmpty) {
      return const InvalidDeepLink(reason: 'Track link missing ID');
    }

    if (segments.first == 'secret') {
      if (segments.length < 2 || segments[1].isEmpty) {
        return const InvalidDeepLink(reason: 'Secret track link missing token');
      }

      return SecretTrackDeepLink(secretToken: segments[1]);
    }

    final trackId = segments.first;
    if (trackId.isEmpty) {
      return const InvalidDeepLink(reason: 'Track ID is empty');
    }

    return TrackDeepLink(trackId: trackId);
  }

  static DeepLinkDestination _parseUser(List<String> segments) {
    if (segments.isEmpty || segments.first.isEmpty) {
      return const InvalidDeepLink(reason: 'User link missing handle');
    }

    return ProfileDeepLink(handle: segments.first);
  }

  static DeepLinkDestination _parsePlaylist(List<String> segments) {
    if (segments.isEmpty || segments.first.isEmpty) {
      return const InvalidDeepLink(reason: 'Playlist link missing ID');
    }

    if (segments.first == 'secret') {
      if (segments.length < 2 || segments[1].isEmpty) {
        return const InvalidDeepLink(
          reason: 'Secret playlist link missing token',
        );
      }

      return SecretPlaylistDeepLink(secretToken: segments[1]);
    }

    return PlaylistDeepLink(playlistId: segments.first);
  }

  static DeepLinkDestination _parseSearch(Map<String, String> params) {
    final String? query = params['q'];

    if (query == null || query.trim().isEmpty) {
      return const InvalidDeepLink(reason: 'Search link missing query');
    }

    return SearchDeepLink(query: query.trim());
  }

  static DeepLinkDestination _parseResolvableUri(Uri uri) {
    final rawUrl = uri.queryParameters['url'];

    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return const InvalidDeepLink(reason: 'Resolve link missing url');
    }

    return ResolvableResourceDeepLink(url: rawUrl.trim());
  }

  static DeepLinkDestination _parseBilling(
    List<String> segments,
    Map<String, String> params,
  ) {
    if (segments.isEmpty || segments.first != 'return') {
      return const InvalidDeepLink(
        reason: 'Billing link must be soundclone://billing/return',
      );
    }

    return _parseBillingReturn(params);
  }

  static DeepLinkDestination _parseCheckout(
    List<String> segments,
    Map<String, String> params,
  ) {
    if (segments.isEmpty || segments.first != 'return') {
      return const InvalidDeepLink(
        reason: 'Checkout link must be soundclone://checkout/return',
      );
    }

    return _parseBillingReturn(params);
  }

  static BillingReturnDeepLink _parseBillingReturn(
    Map<String, String> params,
  ) {
    return BillingReturnDeepLink(
      sessionId: _readParam(
        params,
        const <String>[
          'session_id',
          'sessionId',
          'billing_session_id',
          'billingSessionId',
          'portal_session_id',
          'portalSessionId',
        ],
      ),
      customerId: _readParam(
        params,
        const <String>[
          'customer_id',
          'customerId',
          'stripe_customer_id',
          'stripeCustomerId',
        ],
      ),
      status: _readParam(
        params,
        const <String>[
          'status',
          'payment_status',
          'paymentStatus',
          'billing_status',
          'billingStatus',
        ],
      ),
      planCode: _readParam(
        params,
        const <String>[
          'plan',
          'plan_code',
          'planCode',
          'tier',
          'subscription_type',
          'subscriptionType',
        ],
      ),
      checkoutSessionId: _readParam(
        params,
        const <String>[
          'checkout_session_id',
          'checkoutSessionId',
          'checkout_id',
          'checkoutId',
          'cs',
        ],
      ),
      subscriptionId: _readParam(
        params,
        const <String>[
          'subscription_id',
          'subscriptionId',
          'stripe_subscription_id',
          'stripeSubscriptionId',
          'sub',
        ],
      ),
    );
  }

  static DeepLinkDestination _parseOAuth(
    List<String> segments,
    Map<String, String> params,
  ) {
    if (segments.isEmpty || segments.first != 'callback') {
      return const InvalidDeepLink(
        reason: 'OAuth link must be soundclone://oauth/callback',
      );
    }

    final error = params['error'];
    final errorDescription = params['error_description'];

    if (error != null && error.trim().isNotEmpty) {
      return OAuthCallbackDeepLink(
        error: error.trim(),
        errorDescription: errorDescription?.trim(),
      );
    }

    final code = params['code'];
    final state = params['state'];

    if (code == null || code.trim().isEmpty) {
      return const InvalidDeepLink(
        reason: 'OAuth callback missing authorization code',
      );
    }

    return OAuthCallbackDeepLink(
      code: code.trim(),
      state: state?.trim(),
    );
  }

  static String? _readParam(
    Map<String, String> params,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = params[key]?.trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }
}
