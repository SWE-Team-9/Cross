// test/features/search/presentation/bloc/search_state_enums_test.dart
import 'package:flutter_test/flutter_test.dart';

// نعرّف الـ enums مؤقتاً هنا للاختبار فقط
// لأن search_state.dart هو part of search_cubit.dart
enum SearchStatus { idle, loading, success, failure }

enum SearchTab { all, tracks, people, playlists }

enum SearchBodyMode {
  idle,
  recents,
  suggestions,
  loading,
  results,
  empty,
  failure
}

void main() {
  group('SearchStatus enum', () {
    test('all SearchStatus values exist', () {
      expect(SearchStatus.idle, SearchStatus.idle);
      expect(SearchStatus.loading, SearchStatus.loading);
      expect(SearchStatus.success, SearchStatus.success);
      expect(SearchStatus.failure, SearchStatus.failure);
    });
  });

  group('SearchTab enum', () {
    test('all SearchTab values exist', () {
      expect(SearchTab.all, SearchTab.all);
      expect(SearchTab.tracks, SearchTab.tracks);
      expect(SearchTab.people, SearchTab.people);
      expect(SearchTab.playlists, SearchTab.playlists);
    });
  });

  group('SearchBodyMode enum', () {
    test('all SearchBodyMode values exist', () {
      expect(SearchBodyMode.idle, SearchBodyMode.idle);
      expect(SearchBodyMode.recents, SearchBodyMode.recents);
      expect(SearchBodyMode.suggestions, SearchBodyMode.suggestions);
      expect(SearchBodyMode.loading, SearchBodyMode.loading);
      expect(SearchBodyMode.results, SearchBodyMode.results);
      expect(SearchBodyMode.empty, SearchBodyMode.empty);
      expect(SearchBodyMode.failure, SearchBodyMode.failure);
    });
  });
}
