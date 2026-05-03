// coverage:ignore-file
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/models/track.dart';
import '../../../../core/utils/platform_url_utils.dart';
import '../../../../core/widgets/track_row.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../messaging/presentation/widgets/message_user_button.dart';
import '../../../playlists/domain/entities/playlist_entity.dart';
import '../../../playlists/domain/repositories/playlists_repository.dart';
import '../../../social/data/repositories/social_repo.dart';
import '../../../social/domain/events/social_events.dart';
import '../../../upload/domain/entities/managed_track.dart';
import '../../../upload/presentation/models/apply_track_management_result.dart';
import '../../../upload/presentation/models/track_management_result.dart';
import '../../domain/entities/profile_entity.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';
import '../routes/profile_routes.dart';
import '../utils/genre_utils.dart';

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
  bool _isFollowActionInFlight = false;
  bool _didSeedInitialTracks = false;
  Set<String>? _viewerFollowingIds;

  List<ManagedTrack> _managedTracks = const <ManagedTrack>[];
  List<ManagedTrack> _likedTracks = const <ManagedTrack>[];
  List<ManagedTrack> _repostedTracks = const <ManagedTrack>[];
  Future<List<PlaylistEntity>>? _profilePlaylistsFuture;
  Future<List<PlaylistEntity>>? _likedPlaylistsFuture;

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
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final profileState = context.read<ProfileCubit>().state;
    if (!_didSeedInitialTracks && profileState is ProfileLoaded) {
      _didSeedInitialTracks = true;
      _managedTracks = profileState.tracks;
      _likedTracks = profileState.likedTracks;
      _repostedTracks = profileState.repostedTracks;
    }

    _syncFollowState(profileState);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _syncManagedTracks(ProfileState state) {
    if (!mounted) return;

    if (state is ProfileLoaded) {
      setState(() {
        _managedTracks = state.tracks;
        _likedTracks = state.likedTracks;
        _repostedTracks = state.repostedTracks;
      });
    }
  }

  void _syncFollowState(ProfileState state) {
    if (!mounted || _isOwnProfile || _isFollowActionInFlight) return;

    final profile = switch (state) {
      ProfileLoaded s => s.profile,
      ProfileUpdating s => s.currentProfile,
      ProfileUpdateSuccess s => s.updatedProfile,
      ProfileUpdateError s => s.currentProfile,
      ProfileImageUploading s => s.currentProfile,
      ProfileImageUploadError s => s.currentProfile,
      _ => null,
    };

    if (profile == null) return;

    unawaited(_syncFollowStateFromProfile(profile));
  }

  Future<void> _syncFollowStateFromProfile(ProfileEntity profile) async {
    var resolved = profile.isFollowing;

    if (!resolved) {
      resolved = await _viewerFollowsUser(profile.id);
    }

    if (!mounted || _isFollowActionInFlight) return;
    if (_isFollowing != resolved) {
      setState(() {
        _isFollowing = resolved;
      });
    }
  }

  Future<bool> _viewerFollowsUser(String userId) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated || userId.trim().isEmpty) return false;
    if (authState.user.id == userId.trim()) return false;

    final followingIds = await _loadViewerFollowingIds(authState.user.id);
    return followingIds.contains(userId.trim());
  }

  Future<Set<String>> _loadViewerFollowingIds(String viewerId) async {
    if (_viewerFollowingIds != null) return _viewerFollowingIds!;
    if (!getIt.isRegistered<SocialRepo>()) return const <String>{};

    final repo = getIt<SocialRepo>();
    final resolved = <String>{};
    var page = 1;
    const limit = 100;

    try {
      while (true) {
        final users = await repo.getFollowing(viewerId, page, limit: limit);
        for (final user in users) {
          if (user.id.trim().isNotEmpty) {
            resolved.add(user.id.trim());
          }
        }

        if (users.length < limit) break;
        page++;
      }
    } catch (_) {}

    _viewerFollowingIds = resolved;
    return _viewerFollowingIds!;
  }

  Future<void> _toggleFollow(ProfileEntity profile) async {
    if (_isOwnProfile || _isFollowActionInFlight || profile.id.trim().isEmpty) {
      return;
    }

    final previous = _isFollowing;
    setState(() {
      _isFollowActionInFlight = true;
      _isFollowing = !previous;
    });

    try {
      if (!getIt.isRegistered<SocialRepo>()) {
        SocialEvents.emitFollowChanged();
        return;
      }

      final repo = getIt<SocialRepo>();
      if (previous) {
        final result = await repo.unfollowUser(profile.id);
        setState(() {
          _isFollowing = result.isFollowing;
          _viewerFollowingIds?.remove(profile.id);
        });
      } else {
        final result = await repo.followUser(profile.id);
        setState(() {
          _isFollowing = result.isFollowing;
          _viewerFollowingIds?.add(profile.id);
        });
      }
      SocialEvents.emitFollowChanged();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFollowing = previous;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isFollowActionInFlight = false;
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: _handleAuthStateChanges,
      child: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          _syncManagedTracks(state);
          _syncFollowState(state);
        },
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
              _buildLikedTracksTab(profile),
              _buildLikedPlaylistsTab(),
              _buildTracksTab(profile),
              _buildPlaylistsTab(),
              _buildRepostedTracksTab(profile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikedTracksTab(ProfileEntity profile) {
    return _ProfileTracksListTab(
      tracks: _likedTracks,
      artistName: profile.displayName,
      artistHandle: profile.handle,
      source: 'profile_likes',
      emptyIcon: Icons.favorite_border,
      emptyMessage: 'No liked tracks yet',
      showLikesCount: true,
    );
  }

  Widget _buildLikedPlaylistsTab() {
    if (!_isOwnProfile || !getIt.isRegistered<PlaylistsRepository>()) {
      return _buildEmptyTab(
        Icons.favorite_border,
        'No liked playlists yet',
      );
    }

    _likedPlaylistsFuture ??=
        getIt<PlaylistsRepository>().getLikedPlaylists(limit: 100);

    return FutureBuilder<List<PlaylistEntity>>(
      future: _likedPlaylistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final playlists = snapshot.data ?? const <PlaylistEntity>[];
        if (playlists.isEmpty) {
          return _buildEmptyTab(
            Icons.favorite_border,
            'No liked playlists yet',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final next = getIt<PlaylistsRepository>().getLikedPlaylists(
              limit: 100,
            );
            setState(() {
              _likedPlaylistsFuture = next;
            });
            await next;
          },
          child: _ProfilePlaylistsList(playlists: playlists),
        );
      },
    );
  }

  Widget _buildTracksTab(ProfileEntity profile) {
    if (!_isOwnProfile) {
      return _ProfileTracksListTab(
        tracks: _managedTracks,
        artistName: profile.displayName,
        artistHandle: profile.handle,
        source: 'profile_tracks',
        emptyIcon: Icons.music_note_outlined,
        emptyMessage: 'No tracks yet',
      );
    }

    return _ManagedProfileTracksTab(
      tracks: _managedTracks,
      artistName: profile.displayName,
      artistHandle: profile.handle,
      source: 'profile_tracks',
      onManageTap: _openTrackManagement,
    );
  }

  Widget _buildRepostedTracksTab(ProfileEntity profile) {
    return _ProfileTracksListTab(
      tracks: _repostedTracks,
      artistName: profile.displayName,
      artistHandle: profile.handle,
      source: 'profile_reposts',
      emptyIcon: Icons.repeat,
      emptyMessage: 'No reposts yet',
    );
  }

  Widget _buildPlaylistsTab() {
    if (!_isOwnProfile || !getIt.isRegistered<PlaylistsRepository>()) {
      return _buildEmptyTab(Icons.queue_music_outlined, 'No playlists yet');
    }

    _profilePlaylistsFuture ??=
        getIt<PlaylistsRepository>().getMyPlaylists(limit: 100);

    return FutureBuilder<List<PlaylistEntity>>(
      future: _profilePlaylistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final playlists = snapshot.data ?? const <PlaylistEntity>[];
        if (playlists.isEmpty) {
          return _buildEmptyTab(Icons.queue_music_outlined, 'No playlists yet');
        }

        return RefreshIndicator(
          onRefresh: () async {
            final next = getIt<PlaylistsRepository>().getMyPlaylists(
              limit: 100,
            );
            setState(() {
              _profilePlaylistsFuture = next;
            });
            await next;
          },
          child: _ProfilePlaylistsList(playlists: playlists),
        );
      },
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
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isFollowActionInFlight
                          ? null
                          : () => _toggleFollow(profile),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _isFollowing
                              ? Colors.black
                              : const Color(0xFFFF5500),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _isFollowing
                                ? const Color(0xFF555555)
                                : const Color(0xFFFF5500),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _isFollowActionInFlight
                              ? '...'
                              : (_isFollowing ? 'Following' : 'Follow'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MessageUserButton(
                      receiverId: profile.id,
                      enabled: profile.id.trim().isNotEmpty,
                    ),
                  ),
                ],
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
        .map((genre) => favoriteGenreLabel(genre.trim()))
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
          IconButton(
            onPressed: () => ProfileRoutes.goToSuggestedUsers(context),
            icon: const Icon(Icons.group_add_outlined, size: 18),
            color: Colors.white70,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            visualDensity: VisualDensity.compact,
            tooltip: 'Suggested users',
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
      isScrollable: true,
      indicatorColor: const Color(0xFFFF5500),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
      tabs: const [
        Tab(text: 'Likes'),
        Tab(text: 'Liked playlists'),
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
}

class _ProfilePlaylistCover extends StatelessWidget {
  const _ProfilePlaylistCover({required this.playlist});

  final PlaylistEntity playlist;

  @override
  Widget build(BuildContext context) {
    final coverUrl =
        PlatformUrlUtils.normalizeBackendUrl(playlist.coverImageUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 44,
        height: 44,
        color: const Color(0xFF1C1C1C),
        child: coverUrl == null
            ? Icon(
                playlist.visibility.isSecret
                    ? Icons.lock_outline
                    : Icons.queue_music,
                color: const Color(0xFFFF5500),
              )
            : Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  playlist.visibility.isSecret
                      ? Icons.lock_outline
                      : Icons.queue_music,
                  color: const Color(0xFFFF5500),
                ),
              ),
      ),
    );
  }
}

class _ProfilePlaylistsList extends StatelessWidget {
  const _ProfilePlaylistsList({required this.playlists});

  final List<PlaylistEntity> playlists;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: playlists.length,
      separatorBuilder: (_, __) => const Divider(
        color: Colors.white12,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return ListTile(
          leading: _ProfilePlaylistCover(playlist: playlist),
          title: Text(
            playlist.title,
            style: const TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${playlist.tracksCount} tracks • ${playlist.likesCount} likes',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.white54,
          ),
          onTap: () => context.push('/playlist/${playlist.playlistId}'),
        );
      },
    );
  }
}

class _ManagedProfileTracksTab extends StatelessWidget {
  final List<ManagedTrack> tracks;
  final String artistName;
  final String artistHandle;
  final String source;
  final ValueChanged<ManagedTrack> onManageTap;

  const _ManagedProfileTracksTab({
    required this.tracks,
    required this.artistName,
    required this.artistHandle,
    required this.source,
    required this.onManageTap,
  });

  Track _toTrackRowData(ManagedTrack managedTrack) {
    final String? nameFromTrack =
        (managedTrack.artistName ?? '').trim().isNotEmpty
            ? managedTrack.artistName!.trim()
            : null;
    final String? handleFromTrack =
        (managedTrack.artistHandle ?? '').trim().isNotEmpty
            ? managedTrack.artistHandle!.trim()
            : null;

    final resolvedArtist = nameFromTrack ??
        handleFromTrack ??
        (artistName.trim().isNotEmpty ? artistName : 'Unknown Artist');
    final resolvedHandle = handleFromTrack ??
        (artistHandle.trim().isNotEmpty ? artistHandle : null);

    return Track(
      id: managedTrack.id,
      title: managedTrack.title,
      artist: resolvedArtist,
      audioUrl: '',
      artworkUrl: managedTrack.artworkUrl,
      handle: resolvedHandle,
      durationMs: managedTrack.durationInSeconds != null
          ? managedTrack.durationInSeconds! * 1000
          : null,
      likesCount: managedTrack.likesCount,
      repostsCount: managedTrack.repostsCount,
    );
  }

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

    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, __) => const Divider(
        color: Colors.white12,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final managedTrack = tracks[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TrackRow(
              track: _toTrackRowData(managedTrack),
              source: source,
            ),
            if (managedTrack.description != null &&
                managedTrack.description!.trim().isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Text(
                  managedTrack.description!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (managedTrack.tags.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Text(
                  '#${managedTrack.tags.join(' · #')}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => onManageTap(managedTrack),
                  child: const Text('Manage'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileTracksListTab extends StatelessWidget {
  final List<ManagedTrack> tracks;
  final String artistName;
  final String artistHandle;
  final String source;
  final IconData emptyIcon;
  final String emptyMessage;
  final bool showLikesCount;

  const _ProfileTracksListTab({
    required this.tracks,
    required this.artistName,
    required this.artistHandle,
    required this.source,
    required this.emptyIcon,
    required this.emptyMessage,
    this.showLikesCount = false,
  });

  Track _toTrackRowData(ManagedTrack managedTrack) {
    final String? nameFromTrack =
        (managedTrack.artistName ?? '').trim().isNotEmpty
            ? managedTrack.artistName!.trim()
            : null;
    final String? handleFromTrack =
        (managedTrack.artistHandle ?? '').trim().isNotEmpty
            ? managedTrack.artistHandle!.trim()
            : null;

    final resolvedArtist = nameFromTrack ??
        handleFromTrack ??
        (artistName.trim().isNotEmpty ? artistName : 'Unknown Artist');
    final resolvedHandle = handleFromTrack ??
        (artistHandle.trim().isNotEmpty ? artistHandle : null);

    return Track(
      id: managedTrack.id,
      title: managedTrack.title,
      artist: resolvedArtist,
      audioUrl: '',
      artworkUrl: managedTrack.artworkUrl,
      handle: resolvedHandle,
      durationMs: managedTrack.durationInSeconds != null
          ? managedTrack.durationInSeconds! * 1000
          : null,
      likesCount: managedTrack.likesCount,
      repostsCount: managedTrack.repostsCount,
    );
  }

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

    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, __) => const Divider(
        color: Colors.white12,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final track = tracks[index];
        return TrackRow(
          track: _toTrackRowData(track),
          source: source,
          showLikesCount: showLikesCount,
        );
      },
    );
  }
}
