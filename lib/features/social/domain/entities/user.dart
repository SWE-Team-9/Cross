class User {
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
    final dynamic rawAvatarUrl = json['avatarUrl'] ??
        json['avatar_url'] ??
        json['profileImageUrl'] ??
        json['profile_image_url'] ??
        json['profileImage'] ??
        json['profile_image'] ??
        json['imageUrl'] ??
        json['image_url'] ??
        json['photoUrl'] ??
        json['photo_url'] ??
        json['picture'] ??
        json['avatar'];
    final avatar = rawAvatarUrl?.toString().trim();

    return User(
      id: rawId?.toString() ?? '',
      username: rawUsername?.toString() ?? '',
      avatarUrl: (avatar == null || avatar.isEmpty) ? null : avatar,
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
}
