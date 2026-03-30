import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../upload/domain/entities/ManagedTrack.dart';
import '../../../upload/domain/entities/TrackManagementVisibility.dart';
import '../../../upload/presentation/models/applyTrackManagementResult.dart';
import '../../../upload/presentation/models/trackManagementResult.dart';
import '../../domain/entities/profile_entity.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';
import '../routes/profile_routes.dart';
import '../../../../core/utils/platform_url_utils.dart';

class ProfilePage extends StatelessWidget {
  final String handle;
  final ProfileCubit? cubit;

  const ProfilePage({
    super.key,
    required this.handle,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<ProfileCubit>.value(
        value: cubit!,
        child: _ProfilePageBody(handle: handle),
      );
    }

    return BlocProvider<ProfileCubit>(
      create: (_) => getIt<ProfileCubit>()..loadProfile(handle),
      child: _ProfilePageBody(handle: handle),
    );
  }
}

class _ProfilePageBody extends StatefulWidget {
  final String handle;

  const _ProfilePageBody({required this.handle});

  @override
  State<_ProfilePageBody> createState() => _ProfilePageBodyState();
}

class _ProfilePageBodyState extends State<_ProfilePageBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isFollowing = false;

  List<ManagedTrack> _managedTracks = const [
    ManagedTrack(
      id: 'profile-track-1',
      title: 'Midnight Echoes',
      description: 'Owner profile track for Sprint 2 management testing.',
      genreId: 1,
      genreName: 'Ambient',
      tags: <String>['owner', 'ambient'],
      visibility: TrackManagementVisibility.publicTrack,
      durationInSeconds: 212,
    ),
    ManagedTrack(
      id: 'profile-track-2',
      title: 'City Lights',
      description: 'Second owner track for edit/delete testing.',
      genreId: 2,
      genreName: 'Electronic',
      tags: <String>['night', 'synth'],
      visibility: TrackManagementVisibility.privateTrack,
      durationInSeconds: 184,
    ),
  ];

  bool get _isOwnProfile {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.handle == widget.handle;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openTrackManagement(ManagedTrack track) async {
    final result = await context.pushNamed(
      'track-management',
      extra: track,
    );

    if (result is TrackManagementResult && mounted) {
      setState(() {
        _managedTracks = applyTrackManagementResult(
          tracks: _managedTracks,
          result: result,
        );
      });
    }
  }

  void _handleAuthStateChanges(BuildContext context, AuthState state) {
    if (!mounted) return;

    if (state is AuthEmailChangeRequested) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A confirmation link was sent to ${state.newEmail}. Please check your inbox.',
          ),
        ),
      );
    } else if (state is AuthEmailChangeConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email updated successfully. Please sign in again with your new email.',
          ),
        ),
      );
    }
  }

  Future<void> _showChangeEmailDialog() async {
    final parentContext = context;
    final authCubit = parentContext.read<AuthCubit>();

    final formKey = GlobalKey<FormState>();
    final newEmailController = TextEditingController();
    final currentPasswordController = TextEditingController();

    bool obscurePassword = true;
    bool isSubmitting = false;
    String? localError;

    await showDialog<void>(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            String? validateEmail(String? value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Please enter a new email address.';
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(email)) return 'Please enter a valid email address.';
              return null;
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF121212),
              title: const Text('Change email', style: TextStyle(color: Colors.white)),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: validateEmail,
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                          onPressed: isSubmitting ? null : () => setDialogState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your password.' : null,
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 12),
                      Text(localError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5500)),
                  onPressed: isSubmitting ? null : () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;

                    final remaining = authCubit.emailChangeCooldownRemainingSeconds;
                    if (remaining > 0) {
                      setDialogState(() => localError = 'Wait $remaining seconds before resending.');
                      return;
                    }

                    setDialogState(() { isSubmitting = true; localError = null; });
                    await authCubit.requestEmailChange(
                      newEmail: newEmailController.text.trim(),
                      currentPassword: currentPasswordController.text,
                    );

                    if (!mounted) return;
                    final currentState = authCubit.state;

                    if (currentState is AuthEmailChangeRequested) {
                      Navigator.of(dialogContext).pop();
                    } else {
                      setDialogState(() {
                        isSubmitting = false;
                        localError = (currentState is AuthEmailChangeFailure) ? currentState.message : (currentState is AuthError ? currentState.message : 'Action failed.');
                      });
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Send link', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
    newEmailController.dispose();
    currentPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: _handleAuthStateChanges,
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
          }

          if (state is ProfileError) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                    const SizedBox(height: 12),
                    Text(state.message, style: const TextStyle(color: Colors.white70)),
                    TextButton(onPressed: () => context.pop(), child: const Text('Go back')),
                  ],
                ),
              ),
            );
          }

          final profile = switch (state) {
            ProfileLoaded s => s.profile,
            ProfileUpdating s => s.currentProfile,
            ProfileUpdateSuccess s => s.updatedProfile,
            ProfileUpdateError s => s.currentProfile,
            ProfileImageUploading s => s.currentProfile,
            _ => null,
          };

          if (profile == null) return const Scaffold(backgroundColor: Colors.black);
          return _buildBody(context, profile);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProfileEntity profile) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context, profile),
                  _buildUserInfo(context, profile),
                  _buildActionRow(context, profile),
                  _buildTabBar(),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildEmptyTab(Icons.favorite_border, 'No liked tracks yet'),
              _buildTracksTab(),
              _buildEmptyTab(Icons.queue_music_outlined, 'No playlists yet'),
              _buildEmptyTab(Icons.repeat, 'No reposts yet'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTracksTab() {
    if (!_isOwnProfile) return _buildEmptyTab(Icons.music_note_outlined, 'No tracks yet');
    return _ManagedProfileTracksTab(tracks: _managedTracks, onManageTap: _openTrackManagement);
  }

  Widget _buildActionRow(BuildContext context, ProfileEntity profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          if (_isOwnProfile)
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildOwnerActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      onTap: () => ProfileRoutes.goToEditProfile(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildOwnerActionButton(
                      icon: Icons.email,
                      label: 'change Email',
                      onTap: _showChangeEmailDialog,
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isFollowing = !_isFollowing),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _isFollowing ? const Color(0xFFFF5500) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _isFollowing ? const Color(0xFFFF5500) : const Color(0xFF555555)),
                  ),
                  alignment: Alignment.center,
                  child: Text(_isFollowing ? 'Following' : 'Follow', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          const SizedBox(width: 12),
          _circleIconBtn(Icons.shuffle, () {}),
          const SizedBox(width: 8),
          _playButton(),
        ],
      ),
    );
  }

  Widget _buildOwnerActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF555555))),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Flexible(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ProfileEntity profile) {
    final coverUrl = PlatformUrlUtils.normalizeBackendUrl(profile.coverPhotoUrl);
    return SizedBox(
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            height: 150,
            child: coverUrl != null ? Image.network(coverUrl, fit: BoxFit.cover) : Container(color: Colors.grey[900]),
          ),
          Positioned(
            top: 10,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circleIconBtn(Icons.arrow_back, () => context.pop()),
                _circleIconBtn(Icons.more_vert, () {}),
              ],
            ),
          ),
          Positioned(left: 14, bottom: 0, child: _buildAvatar(profile)),
        ],
      ),
    );
  }

  Widget _buildAvatar(ProfileEntity profile) {
    final avatarUrl = PlatformUrlUtils.normalizeBackendUrl(profile.avatarUrl);
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 4)),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: const Color(0xFF5B7BBB),
        backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
        child: avatarUrl == null ? const Icon(Icons.person, size: 56, color: Colors.white54) : null,
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, ProfileEntity profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(profile.displayName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              GestureDetector(
                onTap: () => ProfileRoutes.goToFollowers(context, profile.handle),
                child: const Text('0 Followers', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
              const Text(' · ', style: TextStyle(color: Colors.grey)),
              GestureDetector(
                onTap: () => ProfileRoutes.goToFollowing(context, profile.handle),
                child: const Text('0 Following', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ],
          ),
          if (profile.bio != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(profile.bio!, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: const Color(0xFFFF5500),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
      tabs: const [Tab(text: 'Likes'), Tab(text: 'Tracks'), Tab(text: 'Playlists'), Tab(text: 'Reposts')],
    );
  }

  Widget _buildEmptyTab(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _circleIconBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      style: IconButton.styleFrom(backgroundColor: Colors.black45),
    );
  }

  Widget _playButton() {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Icon(Icons.play_arrow, color: Colors.black),
    );
  }
}

class _ManagedProfileTracksTab extends StatelessWidget {
  final List<ManagedTrack> tracks;
  final ValueChanged<ManagedTrack> onManageTap;

  const _ManagedProfileTracksTab({required this.tracks, required this.onManageTap});

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) return const Center(child: Text('No tracks yet.', style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return ListTile(
          title: Text(track.title, style: const TextStyle(color: Colors.white)),
          subtitle: Text(track.visibility.displayLabel, style: const TextStyle(color: Colors.grey)),
          trailing: OutlinedButton(onPressed: () => onManageTap(track), child: const Text('Manage')),
        );
      },
    );
  }
}