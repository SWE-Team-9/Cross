import 'deep_link_destination.dart';

abstract final class DeepLinkParser {
  static const String _scheme = 'soundclone';

  static DeepLinkDestination parse(Uri uri) {
    if (uri.scheme != _scheme) {
      return const InvalidDeepLink(
        reason: 'Unknown scheme: expected soundclone://',
      );
    }

    final String host = uri.host;
    final List<String> segments = uri.pathSegments;

    switch (host) {
      case 'track':
        return _parseTrack(segments);

      case 'user':
        return _parseUser(segments);

      case 'playlist':
        return _parsePlaylist(segments);

      case 'search':
        return _parseSearch(uri.queryParameters);

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

  static DeepLinkDestination _parseTrack(List<String> segments) {
    if (segments.isEmpty) {
      return const InvalidDeepLink(reason: 'Track link missing ID');
    }

    if (segments.first == 'secret') {
      if (segments.length < 2 || segments[1].isEmpty) {
        return const InvalidDeepLink(
          reason: 'Secret track link missing token',
        );
      }

      return SecretTrackDeepLink(secretToken: segments[1]);
    }

    final String trackId = segments.first;
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

    final String? error = params['error'];
    final String? errorDescription = params['error_description'];

    if (error != null && error.trim().isNotEmpty) {
      return OAuthCallbackDeepLink(
        error: error.trim(),
        errorDescription: errorDescription?.trim(),
      );
    }

    final String? code = params['code'];
    final String? state = params['state'];

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
