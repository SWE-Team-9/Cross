class User {
  final String id;
  final String username;
  bool isFollowing;
  int followersCount;

  User({
    required this.id,
    required this.username,
    this.isFollowing = false,
    this.followersCount = 0,
  });

  User copyWith({
    bool? isFollowing,
    int? followersCount,
  }) {
    return User(
      id: id,
      username: username,
      isFollowing: isFollowing ?? this.isFollowing,
      followersCount: followersCount ?? this.followersCount,
    );
  }
}
