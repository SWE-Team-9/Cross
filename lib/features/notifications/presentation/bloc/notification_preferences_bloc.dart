import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_preferences_entity.dart';
import '../../domain/usecases/notification_preferences_use_cases.dart';
// Ensure this import points to your NotificationsResult file
import '../../domain/entities/notifications_result.dart'; 

abstract class NotificationPreferencesEvent extends Equatable {
  const NotificationPreferencesEvent();

  @override
  List<Object?> get props => const [];
}

class LoadPreferences extends NotificationPreferencesEvent {
  const LoadPreferences();
}

class SavePreferences extends NotificationPreferencesEvent {
  final NotificationPreferencesEntity preferences;

  const SavePreferences(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

class TogglePreference extends NotificationPreferencesEvent {
  final String key;
  final bool value;

  const TogglePreference({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];
}

class NotificationPreferencesState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final NotificationPreferencesEntity preferences;

  const NotificationPreferencesState({
    required this.isLoading,
    required this.isSaving,
    required this.error,
    required this.preferences,
  });

  factory NotificationPreferencesState.initial() {
    return NotificationPreferencesState(
      isLoading: false,
      isSaving: false,
      error: null,
      preferences: NotificationPreferencesEntity.defaults(),
    );
  }

  NotificationPreferencesState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    NotificationPreferencesEntity? preferences,
  }) {
    return NotificationPreferencesState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, error, preferences];
}

class NotificationPreferencesBloc
    extends Bloc<NotificationPreferencesEvent, NotificationPreferencesState> {
  final GetNotificationPreferencesUseCase _getPreferences;
  final UpdateNotificationPreferencesUseCase _updatePreferences;

  NotificationPreferencesBloc({
    required GetNotificationPreferencesUseCase getPreferences,
    required UpdateNotificationPreferencesUseCase updatePreferences,
  })  : _getPreferences = getPreferences,
        _updatePreferences = updatePreferences,
        super(NotificationPreferencesState.initial()) {
    on<LoadPreferences>(_onLoadPreferences);
    on<TogglePreference>(_onTogglePreference);
    on<SavePreferences>(_onSavePreferences);
  }

  Future<void> _onLoadPreferences(
    LoadPreferences event,
    Emitter<NotificationPreferencesState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _getPreferences();

    // Replaced .when with Dart 3 Switch
    switch (result) {
      case NotificationsSuccess(value: final preferences):
        emit(
          state.copyWith(
            isLoading: false,
            clearError: true,
            preferences: preferences,
          ),
        );
      case NotificationsFailure(failure: final f):
        emit(
          state.copyWith(isLoading: false, error: f.message),
        );
      default:
        emit(state.copyWith(isLoading: false, error: 'Unexpected error'));
    }
  }

  Future<void> _onTogglePreference(
    TogglePreference event,
    Emitter<NotificationPreferencesState> emit,
  ) async {
    final current = state.preferences;

    final updated = switch (event.key) {
      'push' => current.copyWith(pushEnabled: event.value),
      'email' => current.copyWith(emailEnabled: event.value),
      'likes' => current.copyWith(likesEnabled: event.value),
      'comments' => current.copyWith(commentsEnabled: event.value),
      'follows' => current.copyWith(followsEnabled: event.value),
      'reposts' => current.copyWith(repostsEnabled: event.value),
      _ => current,
    };

    emit(state.copyWith(preferences: updated, clearError: true));
    add(SavePreferences(updated));
  }

  Future<void> _onSavePreferences(
    SavePreferences event,
    Emitter<NotificationPreferencesState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, clearError: true));

    final result = await _updatePreferences(event.preferences);

    // Replaced .when with Dart 3 Switch
    switch (result) {
      case NotificationsSuccess():
        emit(state.copyWith(isSaving: false, clearError: true));
      case NotificationsFailure(failure: final f):
        emit(state.copyWith(isSaving: false, error: f.message));
      default:
        emit(state.copyWith(isSaving: false, error: 'Failed to save preferences'));
    }
  }
}