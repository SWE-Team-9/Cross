class User {
  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final DateTime? dateOfBirth;
  final bool isPro;
  final bool isProfileCompleted;

  const User({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.dateOfBirth,
    this.isPro = false,
    this.isProfileCompleted = false,
  });
}