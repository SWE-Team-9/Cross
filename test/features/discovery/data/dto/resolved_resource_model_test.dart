import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/discovery/data/dto/resolved_resource_model.dart';
import 'package:soundcloud_clone/features/discovery/domain/entities/resolved_resource.dart';

void main() {
  group('ResolvedResourceModel', () {
    test('parses unmatched resolver response', () {
      final model = ResolvedResourceModel.fromJson({
        'matched': false,
      });

      expect(model.matched, false);
      expect(model.type, ResolvedResourceType.unknown);
      expect(model.resourceId, '');
      expect(model.handle, isNull);
      expect(model.slug, isNull);
    });

    test('parses matched track response', () {
      final model = ResolvedResourceModel.fromJson({
        'matched': true,
        'resourceType': 'TRACK',
        'id': 'trk_123',
        'slug': 'track-slug',
      });

      expect(model.matched, true);
      expect(model.type, ResolvedResourceType.track);
      expect(model.resourceId, 'trk_123');
      expect(model.slug, 'track-slug');
    });

    test('parses matched artist response using handle', () {
      final model = ResolvedResourceModel.fromJson({
        'matched': true,
        'resourceType': 'USER',
        'id': 'usr_123',
        'handle': 'ali-beats',
      });

      expect(model.matched, true);
      expect(model.type, ResolvedResourceType.artist);
      expect(model.resourceId, 'usr_123');
      expect(model.handle, 'ali-beats');
    });

    test('parses matched playlist response', () {
      final model = ResolvedResourceModel.fromJson({
        'matched': true,
        'resourceType': 'PLAYLIST',
        'id': 'pl_123',
        'slug': 'night-mix',
      });

      expect(model.matched, true);
      expect(model.type, ResolvedResourceType.playlist);
      expect(model.resourceId, 'pl_123');
      expect(model.slug, 'night-mix');
    });
  });
}
