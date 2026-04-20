class User {
  static const List<String> _avatarUrlKeys = <String>[
    'avatarUrl',
    'avatar_url',
    'profileImageUrl',
    'profile_image_url',
    'profileImage',
    'profile_image',
    'imageUrl',
    'image_url',
    'photoUrl',
    'photo_url',
    'picture',
    'avatar',
  ];

  final String id;
  final String username;
  final String? avatarUrl;
  final bool isFollowing;
  final int followersCount;

  User({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.isFollowing = false,
    this.followersCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final dynamic rawId =
        json['id'] ?? json['_id'] ?? json['userId'] ?? json['user_id'];

    final dynamic rawUsername = json['username'] ??
        json['handle'] ??
        json['display_name'] ??
        json['displayName'] ??
        '';

    final dynamic rawIsFollowing = json['isFollowing'] ??
        json['is_following'] ??
        json['followedByMe'] ??
        json['followed_by_me'] ??
        json['viewerFollows'] ??
        json['viewer_follows'] ??
        false;

    final dynamic rawFollowersCount =
        json['followersCount'] ?? json['followers_count'] ?? 0;
    final avatar = _firstNonEmptyString(json, _avatarUrlKeys);

    return User(
      id: rawId?.toString() ?? '',
      username: rawUsername?.toString() ?? '',
      avatarUrl: avatar,
      isFollowing: rawIsFollowing is bool
          ? rawIsFollowing
          : rawIsFollowing.toString().toLowerCase() == 'true',
      followersCount: rawFollowersCount is int
          ? rawFollowersCount
          : int.tryParse(rawFollowersCount.toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatarUrl': avatarUrl,
      'isFollowing': isFollowing,
      'followersCount': followersCount,
    };
  }

  User copyWith({
    bool? isFollowing,
    int? followersCount,
  }) {
    return User(
      id: id,
      username: username,
      avatarUrl: avatarUrl,
      isFollowing: isFollowing ?? this.isFollowing,
      followersCount: followersCount ?? this.followersCount,
    );
  }

  static String? _firstNonEmptyString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final parsed = value.toString().trim();
      if (parsed.isNotEmpty) return parsed;
    }
    return null;
  }
}
