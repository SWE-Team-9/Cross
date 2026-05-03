import 'package:equatable/equatable.dart';

enum ResolvedResourceType { track, artist, playlist, unknown }

class ResolvedResource extends Equatable {
  const ResolvedResource({
    required this.matched,
    required this.type,
    required this.resourceId,
    this.handle,
    this.slug,
  });

  final bool matched;
  final ResolvedResourceType type;
  final String resourceId;
  final String? handle;
  final String? slug;

  @override
  List<Object?> get props => [matched, type, resourceId, handle, slug];
}
