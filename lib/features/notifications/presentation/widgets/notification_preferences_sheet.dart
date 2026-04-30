import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notification_preferences_bloc.dart';

class _NotificationPrefsColors {
  static const orange = Color(0xFFFF5500);
  static const deepBlack = Color(0xFF111111);
  // static const darkGrey = Color(0xFF222222);
}

class NotificationPreferencesSheet extends StatelessWidget {
  const NotificationPreferencesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _NotificationPrefsColors.deepBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const NotificationPreferencesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: BlocBuilder<NotificationPreferencesBloc, NotificationPreferencesState>(
          builder: (context, state) {
            final prefs = state.preferences;
            if (state.isLoading && !state.isSaving) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                    color: _NotificationPrefsColors.orange,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Notification Preferences',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      if (state.isSaving)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _NotificationPrefsColors.orange,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        state.error!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: _NotificationPrefsColors.orange,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  _PrefSwitchTile(
                    label: 'Likes',
                    value: prefs.likesEnabled,
                    onChanged: state.isSaving ? null : (v) => _toggle(context, 'likes', v),
                  ),
                  _PrefSwitchTile(
                    label: 'Comments',
                    value: prefs.commentsEnabled,
                    onChanged: state.isSaving ? null : (v) => _toggle(context, 'comments', v),
                  ),
                  _PrefSwitchTile(
                    label: 'Follows',
                    value: prefs.followsEnabled,
                    onChanged: state.isSaving ? null : (v) => _toggle(context, 'follows', v),
                  ),
                  _PrefSwitchTile(
                    label: 'Reposts',
                    value: prefs.repostsEnabled,
                    onChanged: state.isSaving ? null : (v) => _toggle(context, 'reposts', v),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _toggle(BuildContext context, String key, bool value) {
    context
        .read<NotificationPreferencesBloc>()
        .add(TogglePreference(key: key, value: value));
  }
}

class _PrefSwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _PrefSwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      activeThumbColor: _NotificationPrefsColors.orange,
      activeTrackColor: _NotificationPrefsColors.orange.withValues(alpha: 0.5),
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onChanged: onChanged,
    );
  }
}