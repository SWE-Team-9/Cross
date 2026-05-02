class OfflineTrackEntitlement {
  final String trackId;
  final String title;
  final String artist;
  final String handle;
  final int durationMs;
  final String? coverArtUrl;
  final String downloadUrl;
  final DateTime? expiresAt;
  final int expiresInSeconds;
  final String offlineTokenId;
  final String planCode;

  const OfflineTrackEntitlement({
    this.trackId = '',
    this.title = '',
    this.artist = '',
    this.handle = '',
    this.durationMs = 0,
    this.coverArtUrl,
    this.downloadUrl = '',
    this.expiresAt,
    this.expiresInSeconds = 0,
    this.offlineTokenId = '',
    this.planCode = '',
  });

  String get normalizedPlanCode => planCode.trim().toUpperCase();

  bool get isAllowed => normalizedPlanCode != 'FREE';

  bool get isPro => normalizedPlanCode == 'PRO';

  bool get isGoPlus => normalizedPlanCode == 'GO_PLUS';

  bool get hasCoverArt => coverArtUrl != null && coverArtUrl!.trim().isNotEmpty;

  bool get hasDownloadUrl => downloadUrl.trim().isNotEmpty;

  bool get hasOfflineToken => offlineTokenId.trim().isNotEmpty;

  bool get isExpired {
    final expiry = expiresAt;
    if (expiry == null) {
      return false;
    }

    return DateTime.now().toUtc().isAfter(expiry.toUtc());
  }

  String get displayTitle => title.trim().isEmpty ? 'Untitled' : title;

  String get displayArtist => artist.trim().isEmpty ? 'Unknown artist' : artist;

  Duration get duration => Duration(milliseconds: durationMs < 0 ? 0 : durationMs);

  factory OfflineTrackEntitlement.fromJson(Map<String, dynamic> json) {
    return OfflineTrackEntitlement(
      trackId: _asString(json['trackId'] ?? json['track_id'] ?? json['id']),
      title: _asString(json['title']),
      artist: _asString(json['artist'] ?? json['artistName']),
      handle: _asString(json['handle'] ?? json['artistHandle']),
      durationMs: _asInt(json['durationMs'] ?? json['duration_ms']),
      coverArtUrl: _asNullableString(
        json['coverArtUrl'] ?? json['cover_art_url'] ?? json['artworkUrl'],
      ),
      downloadUrl: _asString(json['downloadUrl'] ?? json['download_url']),
      expiresAt: _asDate(json['expiresAt'] ?? json['expires_at']),
      expiresInSeconds: _asInt(
        json['expiresInSeconds'] ?? json['expires_in_seconds'],
      ),
      offlineTokenId: _asString(
        json['offlineTokenId'] ?? json['offline_token_id'],
      ),
      planCode: _asString(json['planCode'] ?? json['plan_code']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'trackId': trackId,
      'title': title,
      'artist': artist,
      'handle': handle,
      'durationMs': durationMs,
      'coverArtUrl': coverArtUrl,
      'downloadUrl': downloadUrl,
      'expiresAt': expiresAt?.toIso8601String(),
      'expiresInSeconds': expiresInSeconds,
      'offlineTokenId': offlineTokenId,
      'planCode': planCode,
    };
  }

  OfflineTrackEntitlement copyWith({
    String? trackId,
    String? title,
    String? artist,
    String? handle,
    int? durationMs,
    String? coverArtUrl,
    bool clearCoverArtUrl = false,
    String? downloadUrl,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    int? expiresInSeconds,
    String? offlineTokenId,
    String? planCode,
  }) {
    return OfflineTrackEntitlement(
      trackId: trackId ?? this.trackId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      handle: handle ?? this.handle,
      durationMs: durationMs ?? this.durationMs,
      coverArtUrl: clearCoverArtUrl ? null : coverArtUrl ?? this.coverArtUrl,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      expiresAt: clearExpiresAt ? null : expiresAt ?? this.expiresAt,
      expiresInSeconds: expiresInSeconds ?? this.expiresInSeconds,
      offlineTokenId: offlineTokenId ?? this.offlineTokenId,
      planCode: planCode ?? this.planCode,
    );
  }

  @override
  String toString() {
    return 'OfflineTrackEntitlement(trackId: $trackId, title: $title, '
        'planCode: $planCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OfflineTrackEntitlement &&
            runtimeType == other.runtimeType &&
            trackId == other.trackId &&
            title == other.title &&
            artist == other.artist &&
            handle == other.handle &&
            durationMs == other.durationMs &&
            coverArtUrl == other.coverArtUrl &&
            downloadUrl == other.downloadUrl &&
            expiresAt == other.expiresAt &&
            expiresInSeconds == other.expiresInSeconds &&
            offlineTokenId == other.offlineTokenId &&
            planCode == other.planCode;
  }

  @override
  int get hashCode {
    return Object.hash(
      trackId,
      title,
      artist,
      handle,
      durationMs,
      coverArtUrl,
      downloadUrl,
      expiresAt,
      expiresInSeconds,
      offlineTokenId,
      planCode,
    );
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  final parsed = value?.toString().trim() ?? '';
  return parsed.isEmpty ? fallback : parsed;
}

String? _asNullableString(dynamic value) {
  final parsed = _asString(value);
  return parsed.isEmpty ? null : parsed;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _asDate(dynamic value) {
  if (value is DateTime) return value;

  final parsed = value?.toString().trim() ?? '';
  if (parsed.isEmpty) return null;

  return DateTime.tryParse(parsed);
}