class User {
  final String id;
  final String email;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final String? gender;
  final DateTime? dateOfBirth;
  final bool isVerified;
  final bool isPro;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.dateOfBirth,
    this.isVerified = false,
    this.isPro = false,
  });
}
