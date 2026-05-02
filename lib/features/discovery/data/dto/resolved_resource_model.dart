import '../../domain/entities/resolved_resource.dart';

class ResolvedResourceModel extends ResolvedResource {
  const ResolvedResourceModel({
    required super.type,
    required super.resourceId,
    super.ownerId,
  });

  factory ResolvedResourceModel.fromJson(Map<String, dynamic> json) {
    return ResolvedResourceModel(
      type: _parseType(json['type'] as String? ?? ''),
      resourceId: json['resource_id'] as String,
      ownerId: json['owner_id'] as String?,
    );
  }

  static ResolvedResourceType _parseType(String raw) {
    switch (raw.toUpperCase()) {
      case 'TRACK':
        return ResolvedResourceType.track;
      case 'ARTIST':
        return ResolvedResourceType.artist;
      case 'PLAYLIST':
        return ResolvedResourceType.playlist;
      default:
        return ResolvedResourceType.unknown;
    }
  }
}