import 'package:equatable/equatable.dart';

class NotificationPreferencesEntity extends Equatable {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool likesEnabled;
  final bool commentsEnabled;
  final bool followsEnabled;
  final bool repostsEnabled;

  const NotificationPreferencesEntity({
    required this.pushEnabled,
    required this.emailEnabled,
    required this.likesEnabled,
    required this.commentsEnabled,
    required this.followsEnabled,
    required this.repostsEnabled,
  });

  /// Sensible defaults used as the BLoC's initial state.
  factory NotificationPreferencesEntity.defaults() {
    return const NotificationPreferencesEntity(
      pushEnabled: true,
      emailEnabled: true,
      likesEnabled: true,
      commentsEnabled: true,
      followsEnabled: true,
      repostsEnabled: true,
    );
  }

  NotificationPreferencesEntity copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? likesEnabled,
    bool? commentsEnabled,
    bool? followsEnabled,
    bool? repostsEnabled,
  }) {
    return NotificationPreferencesEntity(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      likesEnabled: likesEnabled ?? this.likesEnabled,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      followsEnabled: followsEnabled ?? this.followsEnabled,
      repostsEnabled: repostsEnabled ?? this.repostsEnabled,
    );
  }

  @override
  List<Object?> get props => [
        pushEnabled,
        emailEnabled,
        likesEnabled,
        commentsEnabled,
        followsEnabled,
        repostsEnabled,
      ];
}