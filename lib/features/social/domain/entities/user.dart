class User {
  final String id;
  final String username;
  final bool isFollowing;
  final int followersCount;

  User({
    required this.id,
    required this.username,
    this.isFollowing = false,
    this.followersCount = 0,
  });


  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      isFollowing: json['isFollowing'] ?? false,
      followersCount: json['followersCount'] ?? 0,
    );
  }

  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
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
      isFollowing: isFollowing ?? this.isFollowing,
      followersCount: followersCount ?? this.followersCount,
    );
  }
}