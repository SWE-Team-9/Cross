import '../../domain/entities/resolved_resource.dart';

class ResolvedResourceModel extends ResolvedResource {
  const ResolvedResourceModel({
    required super.matched,
    required super.type,
    required super.resourceId,
    super.handle,
    super.slug,
  });

  factory ResolvedResourceModel.fromJson(Map<String, dynamic> json) {
    final matched = json['matched'] as bool? ?? false;

    if (!matched) {
      return const ResolvedResourceModel(
        matched: false,
        type: ResolvedResourceType.unknown,
        resourceId: '',
      );
    }

    return ResolvedResourceModel(
      matched: true,
      type: _parseType(json['resourceType'] ?? json['type']),
      resourceId: _s(json['id'] ?? json['resource_id'] ?? json['resourceId']),
      handle: _nullableString(json['handle']),
      slug: _nullableString(json['slug']),
    );
  }

  static ResolvedResourceType _parseType(dynamic raw) {
    switch (raw?.toString().trim().toUpperCase()) {
      case 'TRACK':
        return ResolvedResourceType.track;
      case 'ARTIST':
      case 'USER':
      case 'PROFILE':
        return ResolvedResourceType.artist;
      case 'PLAYLIST':
        return ResolvedResourceType.playlist;
      default:
        return ResolvedResourceType.unknown;
    }
  }

  static String _s(dynamic value) => value?.toString() ?? '';

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
