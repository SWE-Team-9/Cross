import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notification_preferences_bloc.dart';

class NotificationPreferencesSheet extends StatelessWidget {
  const NotificationPreferencesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const NotificationPreferencesSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: BlocBuilder<NotificationPreferencesBloc,
            NotificationPreferencesState>(
          builder: (context, state) {
            final prefs = state.preferences;
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
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (state.isSaving)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        state.error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  _PrefSwitchTile(
                    label: 'Push notifications',
                    value: prefs.pushEnabled,
                    onChanged: (v) => _toggle(context, 'push', v),
                  ),
                  _PrefSwitchTile(
                    label: 'Email notifications',
                    value: prefs.emailEnabled,
                    onChanged: (v) => _toggle(context, 'email', v),
                  ),
                  const Divider(height: 18),
                  _PrefSwitchTile(
                    label: 'Likes',
                    value: prefs.likesEnabled,
                    onChanged: (v) => _toggle(context, 'likes', v),
                  ),
                  _PrefSwitchTile(
                    label: 'Comments',
                    value: prefs.commentsEnabled,
                    onChanged: (v) => _toggle(context, 'comments', v),
                  ),
                  _PrefSwitchTile(
                    label: 'Follows',
                    value: prefs.followsEnabled,
                    onChanged: (v) => _toggle(context, 'follows', v),
                  ),
                  _PrefSwitchTile(
                    label: 'Reposts',
                    value: prefs.repostsEnabled,
                    onChanged: (v) => _toggle(context, 'reposts', v),
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
  final ValueChanged<bool> onChanged;

  const _PrefSwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      onChanged: onChanged,
    );
  }
}
