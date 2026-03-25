import '../../domain/entities/user.dart';

class UserDto {
  final String id;
  final String email;
  final String? displayName;
  final String handle;
  final String? username;
  final String? dateOfBirth;
  final String? gender;
  final bool isVerified;
  final String? avatarUrl;
  final String? bio;
  final bool isPro;

  const UserDto({
    required this.id,
    required this.email,
    this.displayName,
    required this.handle,
    this.username,
    this.dateOfBirth,
    this.gender,
    required this.isVerified,
    this.avatarUrl,
    this.bio,
    this.isPro = false,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'],
      handle: (json['handle'] ?? json['username'] ?? '').toString(),
      username: json['username'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      isVerified: json['is_verified'] ?? false,
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      isPro: json['is_pro'] ?? false,
    );
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      handle: handle,
      username: username,
      avatarUrl: avatarUrl,
      bio: bio,
      gender: gender,
      dateOfBirth: dateOfBirth != null ? DateTime.tryParse(dateOfBirth!) : null,
      isVerified: isVerified,
      isPro: isPro,
    );
  }
}
