import 'package:equatable/equatable.dart';

enum ProfileImageType {
  avatar,
  cover,
}

extension ProfileImageTypeX on ProfileImageType {
  String get displayName =>
      this == ProfileImageType.avatar ? 'Avatar' : 'Cover';

  String get endpointSegment =>
      this == ProfileImageType.avatar ? 'avatar' : 'cover';

  int get maxFileSizeInBytes =>
      this == ProfileImageType.avatar ? 5 * 1024 * 1024 : 15 * 1024 * 1024;

  double get cropAspectRatio => this == ProfileImageType.avatar ? 1.0 : 16 / 9;
}

class ProfileImageUploadResult extends Equatable {
  const ProfileImageUploadResult({
    required this.type,
    required this.url,
    required this.key,
  });

  final ProfileImageType type;
  final String url;
  final String key;

  @override
  List<Object?> get props => [
        type,
        url,
        key,
      ];
}
