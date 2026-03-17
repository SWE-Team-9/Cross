import '../../domain/entities/user.dart';

class UserDto {
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

  const UserDto({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.gender,
    this.dateOfBirth,
    required this.isPro,
    required this.isProfileCompleted,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      username: json['username'],
      displayName: json['display_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
      isPro: json['is_pro'] ?? false,
      isProfileCompleted: json['is_profile_completed'] ?? false,
    );
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
      gender: gender,
      dateOfBirth: dateOfBirth,
      isPro: isPro,
      isProfileCompleted: isProfileCompleted,
    );
  }
}