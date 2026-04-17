import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/utils/platform_url_utils.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../playback/domain/usecases/get_track_detail_use_case.dart';
import '../../../playback/presentation/bloc/player_cubit.dart';
import '../../../upload/domain/entities/managed_track.dart';
import '../../../upload/presentation/models/apply_track_management_result.dart';
import '../../../upload/presentation/models/track_management_result.dart';
import '../../domain/entities/profile_entity.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';
import '../routes/profile_routes.dart';

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
      create: (context) {
        final authState = context.read<AuthCubit>().state;
        final profileCubit = getIt<ProfileCubit>();

        if (authState is AuthAuthenticated && authState.user.handle == handle) {
          profileCubit.loadOwnProfile();
        } else {
          profileCubit.loadProfile(handle);
        }

        return profileCubit;
      },
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
  bool _didSeedInitialTracks = false;

  List<ManagedTrack> _managedTracks = const <ManagedTrack>[];
  List<ManagedTrack> _likedTracks = const <ManagedTrack>[];
  List<ManagedTrack> _repostedTracks = const <ManagedTrack>[];

  bool get _isOwnProfile {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.handle == widget.handle;
    }
    return false;
  }

  // ── Lifecycle Methods ───────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didSeedInitialTracks) return;
    _didSeedInitialTracks = true;

    final profileState = context.read<ProfileCubit>().state;
    if (_isOwnProfile && profileState is ProfileLoaded) {
      _managedTracks = profileState.tracks;
      _likedTracks = profileState.likedTracks;
      _repostedTracks = profileState.repostedTracks;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Action Methods ──────────────────────────────────────────────────────

  void _syncManagedTracks(ProfileState state) {
    if (!mounted || !_isOwnProfile) return;

    if (state is ProfileLoaded) {
      setState(() {
        _managedTracks = state.tracks;
        _likedTracks = state.likedTracks;
        _repostedTracks = state.repostedTracks;
      });
    }
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

  Future<void> _playTrack(ManagedTrack managedTrack) async {
    try {
      final getTrackDetailUseCase = getIt<GetTrackDetailUseCase>();
      final result = await getTrackDetailUseCase(managedTrack.id);

      if (result.failure != null || result.detail == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to play track: ${result.failure?.message ?? 'Unknown error'}',
            ),
          ),
        );
        return;
      }

      final detail = result.detail!;
      await getIt<PlayerCubit>().play(detail.toPlaybackTrack());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing track: $e')),
      );
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
              if (!emailRegex.hasMatch(email)) {
                return 'Please enter a valid email address.';
              }
              return null;
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF121212),
              title: const Text(
                'Change email',
                style: TextStyle(color: Colors.white),
              ),
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
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                          ? 'Please enter your password.'
                          : null,
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        localError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5500),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          final remaining =
                              authCubit.emailChangeCooldownRemainingSeconds;
                          if (remaining > 0) {
                            setDialogState(
                              () => localError =
                                  'Wait $remaining seconds before resending.',
                            );
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

                          if (!mounted) return;
                          final currentState = authCubit.state;

                          if (currentState is AuthEmailChangeRequested) {
                            Navigator.of(dialogContext).pop();
                          } else {
                            setDialogState(() {
                              isSubmitting = false;
                              localError =
                                  (currentState is AuthEmailChangeFailure)
                                      ? currentState.message
                                      : (currentState is AuthError
                                          ? currentState.message
                                          : 'Action failed.');
                            });
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Send link',
                          style: TextStyle(color: Colors.white),
                        ),
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

  Future<void> _openExternalLink(
    BuildContext context,
    String platform,
    String rawUrl,
  ) async {
    try {
      final normalized = _normalizeForLaunch(rawUrl);
      final uri = Uri.tryParse(normalized);

      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid link'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open ${_labelForPlatform(platform)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open link'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _normalizeForLaunch(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      return trimmed;
    }

    return 'https://$trimmed';
  }

  // ── Main Build Method ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: _handleAuthStateChanges,
      child: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) => _syncManagedTracks(state),
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is ProfileError) {
              return Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white54,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.message,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Go back'),
                      ),
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
              ProfileImageUploadError s => s.currentProfile,
              _ => null,
            };

            if (profile == null) {
              return const Scaffold(backgroundColor: Colors.black);
            }

            return _buildBody(context, profile);
          },
        ),
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
              _buildLikedTracksTab(),
              _buildTracksTab(),
              _buildEmptyTab(Icons.queue_music_outlined, 'No playlists yet'),
              _buildRepostedTracksTab(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab Builders ────────────────────────────────────────────────────────

  Widget _buildLikedTracksTab() {
    if (!_isOwnProfile) {
      return _buildEmptyTab(Icons.favorite_border, 'No liked tracks yet');
    }

    return _ProfileTracksListTab(
      tracks: _likedTracks,
      emptyIcon: Icons.favorite_border,
      emptyMessage: 'No liked tracks yet',
      onPlayTap: _playTrack,
    );
  }

  Widget _buildTracksTab() {
    if (!_isOwnProfile) {
      // NOTE: You can change this later to fetch public tracks for other users
      return _buildEmptyTab(Icons.music_note_outlined, 'No tracks yet');
    }

    return _ManagedProfileTracksTab(
      tracks: _managedTracks,
      onManageTap: _openTrackManagement,
      onPlayTap: _playTrack,
    );
  }

  Widget _buildRepostedTracksTab() {
    if (!_isOwnProfile) {
      return _buildEmptyTab(Icons.repeat, 'No reposts yet');
    }

    return _ProfileTracksListTab(
      tracks: _repostedTracks,
      emptyIcon: Icons.repeat,
      emptyMessage: 'No reposts yet',
      onPlayTap: _playTrack,
    );
  }

  Widget _buildEmptyTab(IconData icon, String message) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.white24),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white38),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── UI Components ───────────────────────────────────────────────────────

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
                    color: _isFollowing
                        ? const Color(0xFFFF5500)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isFollowing
                          ? const Color(0xFFFF5500)
                          : const Color(0xFF555555),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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

  Widget _buildOwnerActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF555555)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ProfileEntity profile) {
    final coverUrl =
        PlatformUrlUtils.normalizeBackendUrl(profile.coverPhotoUrl);

    return SizedBox(
      height: 230,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: double.infinity,
            height: 150,
            child: coverUrl != null
                ? Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[900],
                    ),
                  )
                : Container(color: Colors.grey[900]),
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
          Positioned(
            left: 14,
            bottom: 0,
            child: _buildAvatar(profile),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ProfileEntity profile) {
    final avatarUrl = PlatformUrlUtils.normalizeBackendUrl(profile.avatarUrl);
    final ImageProvider<Object>? avatarImage =
        avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 4),
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: const Color(0xFF5B7BBB),
        backgroundImage: avatarImage,
        onBackgroundImageError: avatarImage != null ? (_, __) {} : null,
        child: avatarUrl == null
            ? const Icon(
                Icons.person,
                size: 56,
                color: Colors.white54,
              )
            : null,
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, ProfileEntity profile) {
    final mergedLinks = <String, String>{};

    final website = (profile.website ?? '').trim();
    if (website.isNotEmpty) {
      mergedLinks['website'] = website;
    }

    for (final entry in profile.externalLinks.entries) {
      if (entry.value.trim().isEmpty) continue;
      mergedLinks[entry.key] = entry.value.trim();
    }

    final bio = (profile.bio ?? '').trim();
    final location = (profile.location ?? '').trim();
    final favoriteGenres = profile.favoriteGenres
        .map((genre) => _genreLabelFromSlug(genre.trim()))
        .where((genre) => genre.isNotEmpty)
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                profile.accountTier == AccountTier.ARTIST
                    ? 'Artist'
                    : 'Listener',
                profile.accountTier == AccountTier.ARTIST
                    ? Icons.mic
                    : Icons.headphones,
              ),
              if (profile.isPrivate)
                _buildInfoChip('Private', Icons.lock_outline),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    ProfileRoutes.goToFollowers(context, profile.handle),
                child: Text(
                  '${profile.followersCount} Followers',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const Text(' · ', style: TextStyle(color: Colors.grey)),
              GestureDetector(
                onTap: () =>
                    ProfileRoutes.goToFollowing(context, profile.handle),
                child: Text(
                  '${profile.followingCount} Following',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => ProfileRoutes.goToSuggestedUsers(context),
            icon: const Icon(Icons.group_add_outlined, size: 16),
            label: const Text('Suggested users'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: const Size(0, 0),
            ),
          ),
          if (favoriteGenres.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: favoriteGenres
                  .map(
                    (genre) => _buildInfoChip(
                      genre,
                      Icons.local_offer_outlined,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (location.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  location,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          if (website.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              website,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bio,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          if (mergedLinks.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildExternalLinksRow(context, mergedLinks),
          ],
        ],
      ),
    );
  }

  Widget _buildExternalLinksRow(
    BuildContext context,
    Map<String, String> links,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: links.entries.map((entry) {
        final platform = entry.key.trim().toLowerCase();
        final url = entry.value.trim();

        return Tooltip(
          message: '${_labelForPlatform(platform)}\n$url',
          child: InkWell(
            onTap: () => _openExternalLink(context, platform, url),
            onLongPress: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_labelForPlatform(platform)} link copied'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Icon(
                _iconForPlatform(platform),
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForPlatform(String platform) {
    switch (platform) {
      case 'website':
        return Icons.language;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'youtube':
        return Icons.ondemand_video;
      case 'soundcloud':
        return Icons.music_note;
      case 'tiktok':
        return Icons.audiotrack;
      case 'x':
        return Icons.alternate_email;
      case 'facebook':
        return Icons.facebook;
      default:
        return Icons.link;
    }
  }

  String _labelForPlatform(String platform) {
    switch (platform) {
      case 'website':
        return 'Website';
      case 'instagram':
        return 'Instagram';
      case 'youtube':
        return 'YouTube';
      case 'soundcloud':
        return 'SoundCloud';
      case 'tiktok':
        return 'TikTok';
      case 'x':
        return 'X';
      case 'facebook':
        return 'Facebook';
      default:
        return platform;
    }
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: const Color(0xFFFF5500),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
      tabs: const [
        Tab(text: 'Likes'),
        Tab(text: 'Tracks'),
        Tab(text: 'Playlists'),
        Tab(text: 'Reposts'),
      ],
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
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.play_arrow, color: Colors.black),
    );
  }

  String _genreLabelFromSlug(String value) {
    final slug = value.trim().toLowerCase();
    switch (slug) {
      case 'hip-hop':
        return 'Hip Hop';
      case 'r-b-soul':
        return 'R&B / Soul';
      case 'drum-bass':
        return 'Drum & Bass';
      case 'deep-house':
        return 'Deep House';
      case 'lo-fi':
        return 'Lo-fi';
      case 'spoken-word':
        return 'Spoken Word';
      case 'folk-singer-songwriter':
        return 'Folk / Singer-Songwriter';
      default:
        return slug
            .split('-')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
    }
  }
}

// ── Shared Sub-Widgets ──────────────────────────────────────────────────

class _ManagedProfileTracksTab extends StatelessWidget {
  final List<ManagedTrack> tracks;
  final ValueChanged<ManagedTrack> onManageTap;
  final ValueChanged<ManagedTrack> onPlayTap;

  const _ManagedProfileTracksTab({
    required this.tracks,
    required this.onManageTap,
    required this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const Center(
        child: Text(
          'No tracks yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return GestureDetector(
          onTap: () => onPlayTap(track),
          child: ListTile(
            title: Text(
              track.title,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.visibility.name,
                  style: const TextStyle(color: Colors.grey),
                ),
                if ((track.description ?? '').trim().isNotEmpty)
                  Text(
                    track.description!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                if (track.tags.isNotEmpty)
                  Text(
                    track.tags.map((tag) => '#$tag').join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60),
                  ),
              ],
            ),
            trailing: OutlinedButton(
              onPressed: () => onManageTap(track),
              child: const Text('Manage'),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileTracksListTab extends StatelessWidget {
  final List<ManagedTrack> tracks;
  final IconData emptyIcon;
  final String emptyMessage;
  final ValueChanged<ManagedTrack> onPlayTap;

  const _ProfileTracksListTab({
    required this.tracks,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.onPlayTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(emptyIcon, size: 48, color: Colors.white24),
                  const SizedBox(height: 12),
                  Text(
                    emptyMessage,
                    style: const TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];

        return ListTile(
          onTap: () => onPlayTap(track),
          title: Text(
            track.title,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
}
