import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notifications_result.dart';
import 'package:soundcloud_clone/features/notifications/domain/usecases/notification_preferences_use_cases.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notification_preferences_bloc.dart';

class MockGetPrefs extends Mock implements GetNotificationPreferencesUseCase {}
class MockUpdatePrefs extends Mock implements UpdateNotificationPreferencesUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(NotificationPreferencesEntity.defaults());
  });

  late MockGetPrefs mockGet;
  late MockUpdatePrefs mockUpdate;
  late NotificationPreferencesBloc bloc;

  setUp(() {
    mockGet = MockGetPrefs();
    mockUpdate = MockUpdatePrefs();

    when(() => mockGet()).thenAnswer((_) async => NotificationsResult.success(NotificationPreferencesEntity.defaults()));
    when(() => mockUpdate(any())).thenAnswer((_) async => const NotificationsResult.success(null));

    bloc = NotificationPreferencesBloc(getPreferences: mockGet, updatePreferences: mockUpdate);
  });

  tearDown(() async {
    await bloc.close();
  });

  test('initial state is initial', () {
    expect(bloc.state, NotificationPreferencesState.initial());
  });

  blocTest<NotificationPreferencesBloc, NotificationPreferencesState>(
    'LoadPreferences success path',
    build: () => bloc,
    act: (b) => b.add(const LoadPreferences()),
    expect: () => [
      NotificationPreferencesState.initial().copyWith(isLoading: true, clearError: true),
      isA<NotificationPreferencesState>().having((s) => s.isLoading, 'isLoading', false),
    ],
  );

  blocTest<NotificationPreferencesBloc, NotificationPreferencesState>(
    'SavePreferences failure maps error',
    build: () {
      when(() => mockUpdate(any())).thenAnswer((_) async => const NotificationsResult.failure(ServerFailure('err')));
      return NotificationPreferencesBloc(getPreferences: mockGet, updatePreferences: mockUpdate);
    },
    act: (b) => b.add(SavePreferences(NotificationPreferencesEntity.defaults())),
    expect: () => [
      NotificationPreferencesState.initial().copyWith(isSaving: true, clearError: true),
      isA<NotificationPreferencesState>().having((s) => s.isSaving, 'isSaving', false).having((s) => s.error, 'error', isNotNull),
    ],
  );

  blocTest<NotificationPreferencesBloc, NotificationPreferencesState>(
    'LoadPreferences failure maps error',
    build: () {
      when(() => mockGet()).thenAnswer((_) async => const NotificationsResult.failure(ServerFailure('fail')));
      return NotificationPreferencesBloc(getPreferences: mockGet, updatePreferences: mockUpdate);
    },
    act: (b) => b.add(const LoadPreferences()),
    expect: () => [
      NotificationPreferencesState.initial().copyWith(isLoading: true, clearError: true),
      isA<NotificationPreferencesState>().having((s) => s.isLoading, 'isLoading', false).having((s) => s.error, 'error', isNotNull),
    ],
  );

  blocTest<NotificationPreferencesBloc, NotificationPreferencesState>(
    'TogglePreference updates state and saves successfully',
    build: () => NotificationPreferencesBloc(getPreferences: mockGet, updatePreferences: mockUpdate),
    act: (b) => b.add(const TogglePreference(key: 'likes', value: true)),
    expect: () => [
      NotificationPreferencesState.initial().copyWith(preferences: NotificationPreferencesEntity.defaults().copyWith(likesEnabled: true), clearError: true),
      NotificationPreferencesState.initial().copyWith(preferences: NotificationPreferencesEntity.defaults().copyWith(likesEnabled: true), isSaving: true, clearError: true),
      NotificationPreferencesState.initial().copyWith(preferences: NotificationPreferencesEntity.defaults().copyWith(likesEnabled: true), isSaving: false, clearError: true),
    ],
  );
}
