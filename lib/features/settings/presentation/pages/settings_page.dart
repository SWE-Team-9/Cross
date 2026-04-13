import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/presentation/pages/blocked_users_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;

          return ListView(
            children: [
              // ── Account ──────────────────────────────────────────────────
              _SectionHeader(title: 'Account'),
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Profile',
                subtitle: user != null ? '@${user.handle}' : null,
                onTap: () {
                  if (user != null) {
                    context.push('/profile/${user.handle}');
                  }
                },
              ),
              _SettingsTile(
                icon: Icons.email_outlined,
                title: 'Change email',
                subtitle: user?.email,
                onTap: () => _showChangeEmailDialog(context),
              ),
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Change password',
                onTap: () => _showChangePasswordDialog(context),
              ),
              const _Divider(),

              // ── Privacy ───────────────────────────────────────────────────
              _SectionHeader(title: 'Privacy'),
              _SettingsTile(
                icon: Icons.block,
                title: 'Blocked accounts',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RepositoryProvider.value(
                        value: getIt<SocialRepo>(),
                        child: const BlockedUsersPage(),
                      ),
                    ),
                  );
                },
              ),
              const _Divider(),

              // ── Notifications ─────────────────────────────────────────────
              _SectionHeader(title: 'Notifications'),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Push notifications',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.mail_outline,
                title: 'Email notifications',
                onTap: () {},
              ),
              const _Divider(),

              // ── About ─────────────────────────────────────────────────────
              _SectionHeader(title: 'About'),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'About SoundCloud',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of use',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy policy',
                onTap: () {},
              ),
              const _Divider(),

              // ── Sign out ──────────────────────────────────────────────────
              const SizedBox(height: 8),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () => _confirmLogout(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Sign out',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Sign out?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().logout();
            },
            child: const Text('Sign out',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Change password',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'This feature is coming soon.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangeEmailDialog(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final formKey = GlobalKey<FormState>();
    final newEmailController = TextEditingController();
    final currentPasswordController = TextEditingController();

    bool obscurePassword = true;
    bool isSubmitting = false;
    String? localError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF121212),
              title: const Text('Change email',
                  style: TextStyle(color: Colors.white)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: newEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'New email',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF1C1C1C),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Enter a new email.';
                        final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!regex.hasMatch(email)) return 'Invalid email.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      enabled: !isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: const Color(0xFF1C1C1C),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () => setDialogState(
                                    () => obscurePassword = !obscurePassword,
                                  ),
                        ),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Enter your password.'
                          : null,
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 12),
                      Text(localError!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12),
                          textAlign: TextAlign.center),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5500)),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          final remaining =
                              authCubit.emailChangeCooldownRemainingSeconds;
                          if (remaining > 0) {
                            setDialogState(() => localError =
                                'Wait $remaining seconds before resending.');
                            return;
                          }
                          setDialogState(() {
                            isSubmitting = true;
                            localError = null;
                          });
                          await authCubit.requestEmailChange(
                            newEmail: newEmailController.text.trim(),
                            currentPassword: currentPasswordController.text,
                          );
                          final currentState = authCubit.state;
                          if (currentState is AuthEmailChangeRequested) {
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Confirmation sent to ${currentState.newEmail}'),
                              ),
                            );
                          } else {
                            setDialogState(() {
                              isSubmitting = false;
                              localError =
                                  (currentState is AuthEmailChangeFailure)
                                      ? currentState.message
                                      : 'Action failed.';
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Send link',
                          style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.grey[900],
      thickness: 1,
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}
