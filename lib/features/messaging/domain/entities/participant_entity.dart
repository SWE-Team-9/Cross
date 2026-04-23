class ParticipantEntity {
  final String id;
  final String displayName;
  final String handle;
  final String? avatarUrl;

  const ParticipantEntity({
    required this.id,
    required this.displayName,
    required this.handle,
    required this.avatarUrl,
  });
}