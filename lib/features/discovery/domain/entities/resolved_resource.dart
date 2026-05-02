import 'package:equatable/equatable.dart';

enum ResolvedResourceType { track, artist, playlist, unknown }

class ResolvedResource extends Equatable {
  const ResolvedResource({
    required this.type,
    required this.resourceId,
    this.ownerId,
  });

  final ResolvedResourceType type;
  final String resourceId;
  final String? ownerId;

  @override
  List<Object?> get props => [type, resourceId, ownerId];
}
