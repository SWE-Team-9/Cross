import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/managed_track.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_form.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_management_visibility.dart';

void main() {
  group('TrackManagementForm', () {
    const track = ManagedTrack(
      id: 'track-1',
      title: 'Midnight Echoes',
      description: 'Demo description',
      genreId: 1,
      genreName: 'Ambient',
      tags: <String>['demo', 'sprint2'],
      visibility: TrackManagementVisibility.publicTrack,
    );

    test('fromTrack creates matching form', () {
      final form = TrackManagementForm.fromTrack(track);

      expect(form.title, track.title);
      expect(form.description, track.description);
      expect(form.genreId, track.genreId);
      expect(form.genreName, track.genreName);
      expect(form.tags, track.tags);
      expect(form.visibility, track.visibility);
    });

    test('sanitizedTags trims, deduplicates, and limits count', () {
      final form = TrackManagementForm(
        title: 'Track',
        description: 'Desc',
        genreId: 1,
        genreName: 'Ambient',
        tags: const <String>[
          ' demo ',
          'Demo',
          '',
          'local',
          'mix',
        ],
        visibility: TrackManagementVisibility.publicTrack,
      );

      expect(form.sanitizedTags, const <String>['demo', 'local', 'mix']);
    });

    test('title validation works', () {
      final emptyTitleForm = TrackManagementForm(
        title: '   ',
        description: 'Desc',
        genreId: 1,
        genreName: 'Ambient',
        visibility: TrackManagementVisibility.publicTrack,
      );

      expect(emptyTitleForm.titleValidationError, 'Title is required.');

      final longTitleForm = TrackManagementForm(
        title: 'a' * 256,
        description: 'Desc',
        genreId: 1,
        genreName: 'Ambient',
        visibility: TrackManagementVisibility.publicTrack,
      );

      expect(
        longTitleForm.titleValidationError,
        'Title must be 255 characters or fewer.',
      );
    });

    test('description validation works', () {
      final form = TrackManagementForm(
        title: 'Track',
        description: 'a' * 5001,
        genreId: 1,
        genreName: 'Ambient',
        visibility: TrackManagementVisibility.publicTrack,
      );

      expect(
        form.descriptionValidationError,
        'Description must be 5000 characters or fewer.',
      );
    });

    test('genre validation works', () {
      final form = TrackManagementForm(
        title: 'Track',
        description: 'Desc',
        visibility: TrackManagementVisibility.publicTrack,
      );

      expect(form.genreValidationError, 'Please choose a genre.');
    });

    test('tags validation works for overlong tag', () {
      final form = TrackManagementForm(
        title: 'Track',
        description: 'Desc',
        genreId: 1,
        genreName: 'Ambient',
        tags: <String>['a' * 51],
        visibility: TrackManagementVisibility.publicTrack,
      );

      expect(
        form.tagsValidationError,
        'Each tag must be 50 characters or fewer.',
      );
    });

    test('isMetadataValid is true for valid form', () {
      const form = TrackManagementForm(
        title: 'Track',
        description: 'Desc',
        genreId: 1,
        genreName: 'Ambient',
        tags: <String>['demo'],
        visibility: TrackManagementVisibility.publicTrack,
      );

      expect(form.isMetadataValid, isTrue);
    });

    test('hasMetadataChangesComparedTo detects changes', () {
      final form = TrackManagementForm.fromTrack(track).copyWith(
        title: 'Edited Track',
      );

      expect(form.hasMetadataChangesComparedTo(track), isTrue);
    });

    test('hasMetadataChangesComparedTo returns false when unchanged', () {
      final form = TrackManagementForm.fromTrack(track);

      expect(form.hasMetadataChangesComparedTo(track), isFalse);
    });

    test('hasVisibilityChangeComparedTo detects visibility change', () {
      final form = TrackManagementForm.fromTrack(track).copyWith(
        visibility: TrackManagementVisibility.privateTrack,
      );

      expect(form.hasVisibilityChangeComparedTo(track), isTrue);
    });

    test('toMetadataRequestBody maps correctly', () {
      const form = TrackManagementForm(
        title: ' Track ',
        description: ' Description ',
        genreId: 2,
        genreName: 'Electronic',
        tags: <String>[' demo ', 'mix'],
        visibility: TrackManagementVisibility.privateTrack,
      );

      expect(
        form.toMetadataRequestBody(),
        <String, dynamic>{
          'title': 'Track',
          'description': 'Description',
          'genre': 'Electronic',
          'tags': <String>['demo', 'mix'],
        },
      );
    });

    test('toVisibilityRequestBody maps correctly', () {
      const form = TrackManagementForm(
        title: 'Track',
        genreId: 1,
        genreName: 'Ambient',
        visibility: TrackManagementVisibility.privateTrack,
      );

      expect(
        form.toVisibilityRequestBody(),
        <String, dynamic>{
          'visibility': 'PRIVATE',
        },
      );
    });
  });
}
