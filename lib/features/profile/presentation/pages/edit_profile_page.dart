import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/location_utils.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';
import '../widgets/edit_profile_country_picker.dart';
import '../widgets/edit_profile_image_section.dart';
import '../widgets/edit_profile_text_field.dart';
import '../widgets/windows_image_crop_dialog.dart';

class EditProfilePage extends StatefulWidget {
  final Future<String?> Function(ProfileImageType imageType)?
      pickAndCropImageOverride;

  const EditProfilePage({
    super.key,
    this.pickAndCropImageOverride,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _bioController;
  late final TextEditingController _websiteController;

  String _selectedCountry = '';
  late ProfileEntity _initialProfile;
  late AccountTier _selectedAccountTier;
  late bool _isPrivate;
  List<String> _selectedFavoriteGenres = <String>[];
  String? _pendingAvatarImagePath;
  String? _pendingCoverImagePath;

  final List<_EditableExternalLink> _externalLinks = [];

  bool _isApplyingProfile = false;

  static const List<String> _countries = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Argentina',
    'Australia',
    'Austria',
    'Bahrain',
    'Bangladesh',
    'Belgium',
    'Brazil',
    'Canada',
    'Chile',
    'China',
    'Colombia',
    'Croatia',
    'Czech Republic',
    'Denmark',
    'Egypt',
    'Ethiopia',
    'Finland',
    'France',
    'Germany',
    'Ghana',
    'Greece',
    'Hungary',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Italy',
    'Japan',
    'Jordan',
    'Kenya',
    'Kuwait',
    'Lebanon',
    'Libya',
    'Malaysia',
    'Mexico',
    'Morocco',
    'Netherlands',
    'New Zealand',
    'Nigeria',
    'Norway',
    'Oman',
    'Pakistan',
    'Palestine',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Saudi Arabia',
    'Serbia',
    'Singapore',
    'South Africa',
    'South Korea',
    'Spain',
    'Sudan',
    'Sweden',
    'Switzerland',
    'Syria',
    'Thailand',
    'Tunisia',
    'Turkey',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Venezuela',
    'Vietnam',
    'Yemen',
  ];

  static const List<String> _supportedPlatforms = [
    'instagram',
    'youtube',
    'soundcloud',
    'tiktok',
    'x',
    'facebook',
  ];

  static const Map<String, String> _platformLabels = {
    'instagram': 'Instagram',
    'youtube': 'YouTube',
    'soundcloud': 'SoundCloud',
    'tiktok': 'TikTok',
    'x': 'X',
    'facebook': 'Facebook',
  };

  static const List<String> _favoriteGenreOptions = [
    'Ambient',
    'Classical',
    'Dance',
    'Electronic',
    'Hip Hop',
    'House',
    'Indie',
    'Jazz',
    'Pop',
    'R&B',
    'Rock',
    'Techno',
  ];

  bool get _hasUnsavedChanges {
    final currentLocation =
        LocationUtils.build(_cityController.text, _selectedCountry);
    final currentBio = _bioController.text.trim();
    final currentWebsite = _websiteController.text.trim();
    final currentLinks = _buildExternalLinksMap();
    final normalizedFavoriteGenres = _selectedFavoriteGenres
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false)
      ..sort();
    final initialFavoriteGenres = _initialProfile.favoriteGenres
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false)
      ..sort();

    return _displayNameController.text.trim() != _initialProfile.displayName ||
        currentBio != (_initialProfile.bio ?? '') ||
        currentLocation != _initialProfile.location ||
        currentWebsite != (_initialProfile.website ?? '') ||
        _selectedAccountTier != _initialProfile.accountTier ||
        _isPrivate != _initialProfile.isPrivate ||
        !_listEquals(normalizedFavoriteGenres, initialFavoriteGenres) ||
        _pendingAvatarImagePath != null ||
        _pendingCoverImagePath != null ||
        !_mapEquals(currentLinks, _initialProfile.externalLinks);
  }

  @override
  void initState() {
    super.initState();

    _displayNameController = TextEditingController();
    _bioController = TextEditingController();
    _cityController = TextEditingController();
    _websiteController = TextEditingController();

    _displayNameController.addListener(_triggerRebuild);
    _bioController.addListener(_triggerRebuild);
    _cityController.addListener(_triggerRebuild);
    _websiteController.addListener(_triggerRebuild);

    _initialProfile = const ProfileEntity(
      id: '',
      displayName: '',
      handle: '',
      bio: null,
      location: null,
      website: null,
      avatarUrl: null,
      coverPhotoUrl: null,
      accountTier: AccountTier.LISTENER,
      favoriteGenres: [],
      externalLinks: {},
      visibility: ProfileVisibility.PUBLIC,
      followersCount: 0,
      followingCount: 0,
    );
    _selectedAccountTier = AccountTier.LISTENER;
    _isPrivate = false;

    final currentState = context.read<ProfileCubit>().state;
    final currentProfile = _profileFromState(currentState);
    if (currentProfile != null) {
      _applyProfileToForm(currentProfile);
    }
  }

  ProfileEntity? _profileFromState(ProfileState state) {
    if (state is ProfileLoaded) return state.profile;
    if (state is ProfileUpdating) return state.currentProfile;
    if (state is ProfileUpdateError) return state.currentProfile;
    if (state is ProfileImageUploading) return state.currentProfile;
    if (state is ProfileImageUploadError) return state.currentProfile;
    if (state is ProfileUpdateSuccess) return state.updatedProfile;
    return null;
  }

  void _applyProfileToForm(ProfileEntity profile) {
    _isApplyingProfile = true;

    final parsed = LocationUtils.parse(profile.location, _countries);

    _initialProfile = profile;
    _displayNameController.text = profile.displayName;
    _bioController.text = profile.bio ?? '';
    _cityController.text = parsed.city;
    _websiteController.text = profile.website ?? '';
    _selectedCountry = parsed.country;
    _selectedAccountTier = profile.accountTier;
    _isPrivate = profile.isPrivate;
    _selectedFavoriteGenres = profile.favoriteGenres
        .map((genre) => genre.trim())
        .where((genre) => genre.isNotEmpty)
        .toList(growable: false);
    _pendingAvatarImagePath = null;
    _pendingCoverImagePath = null;

    for (final item in _externalLinks) {
      item.dispose();
    }
    _externalLinks.clear();

    for (final entry in profile.externalLinks.entries) {
      final normalizedPlatform = entry.key.trim().toLowerCase();
      if (!_supportedPlatforms.contains(normalizedPlatform)) continue;

      _externalLinks.add(
        _EditableExternalLink(
          platform: normalizedPlatform,
          url: entry.value,
          onChanged: _triggerRebuild,
        ),
      );
    }

    _isApplyingProfile = false;

    if (mounted) {
      setState(() {});
    }
  }

  void _triggerRebuild() {
    if (_isApplyingProfile) return;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _websiteController.dispose();
    for (final link in _externalLinks) {
      link.dispose();
    }
    super.dispose();
  }

  Future<void> _onSaveTapped() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateExternalLinks()) return;
    if (!_hasUnsavedChanges) return;

    final currentLocation =
        LocationUtils.build(_cityController.text, _selectedCountry);

    final String trimmedBio = _bioController.text.trim();
    final String trimmedWebsite = _normalizeUrl(_websiteController.text.trim());
    final normalizedLinks = _buildExternalLinksMap();
    final normalizedFavoriteGenres = _selectedFavoriteGenres
        .map((genre) => genre.trim())
        .where((genre) => genre.isNotEmpty)
        .toList(growable: false)
      ..sort();
    final initialFavoriteGenres = _initialProfile.favoriteGenres
        .map((genre) => genre.trim())
        .where((genre) => genre.isNotEmpty)
        .toList(growable: false)
      ..sort();
    final hadPendingImageChanges =
        _pendingAvatarImagePath != null || _pendingCoverImagePath != null;

    final params = UpdateProfileParams(
      displayName:
          _displayNameController.text.trim() != _initialProfile.displayName
              ? _displayNameController.text.trim()
              : null,
      bio: trimmedBio != (_initialProfile.bio ?? '') ? trimmedBio : null,
      location:
          currentLocation != _initialProfile.location ? currentLocation : null,
      website: trimmedWebsite != (_initialProfile.website ?? '')
          ? trimmedWebsite
          : null,
      accountTier: _selectedAccountTier != _initialProfile.accountTier
          ? _selectedAccountTier
          : null,
      visibility: _isPrivate != _initialProfile.isPrivate
          ? (_isPrivate ? ProfileVisibility.PRIVATE : ProfileVisibility.PUBLIC)
          : null,
      externalLinks: !_mapEquals(normalizedLinks, _initialProfile.externalLinks)
          ? normalizedLinks
          : null,
      favoriteGenres:
          !_listEquals(normalizedFavoriteGenres, initialFavoriteGenres)
              ? normalizedFavoriteGenres
              : null,
    );

    final profileCubit = context.read<ProfileCubit>();
    final authCubit = context.read<AuthCubit>();

    if (_pendingAvatarImagePath != null) {
      await profileCubit.uploadImage(
        imageType: ProfileImageType.AVATAR,
        filePath: _pendingAvatarImagePath!,
      );
      if (!mounted) return;

      final state = profileCubit.state;
      if (state is ProfileImageUploadError &&
          state.imageType == ProfileImageType.AVATAR) {
        return;
      }

      _clearPendingImagePath(ProfileImageType.AVATAR);
    }

    if (_pendingCoverImagePath != null) {
      await profileCubit.uploadImage(
        imageType: ProfileImageType.COVER,
        filePath: _pendingCoverImagePath!,
      );
      if (!mounted) return;

      final state = profileCubit.state;
      if (state is ProfileImageUploadError &&
          state.imageType == ProfileImageType.COVER) {
        return;
      }

      _clearPendingImagePath(ProfileImageType.COVER);
    }

    if (!mounted) return;

    if (params.hasBaseProfileChanges || params.hasExternalLinksChanges) {
      profileCubit.updateProfile(params);
      return;
    }

    if (hadPendingImageChanges) {
      _syncFormWithState(profileCubit.state);
      authCubit.refreshCurrentUserSilently();
    }
  }

  bool _validateExternalLinks() {
    final usedPlatforms = <String>{};

    for (final link in _externalLinks) {
      final platform = link.platform.trim().toLowerCase();
      final rawUrl = link.urlController.text.trim();

      if (rawUrl.isEmpty) continue;

      if (usedPlatforms.contains(platform)) {
        _showFloatingError('Each platform can only be added once.');
        return false;
      }
      usedPlatforms.add(platform);

      final error = _validatePlatformUrl(platform, rawUrl);
      if (error != null) {
        _showFloatingError(error);
        return false;
      }
    }

    final websiteRaw = _websiteController.text.trim();
    if (websiteRaw.isNotEmpty) {
      final normalized = _normalizeUrl(websiteRaw);
      final uri = Uri.tryParse(normalized);
      if (uri == null ||
          !uri.hasScheme ||
          !(uri.isScheme('http') || uri.isScheme('https'))) {
        _showFloatingError('Please enter a valid website URL.');
        return false;
      }
    }

    return true;
  }

  String? _validatePlatformUrl(String platform, String rawUrl) {
    final normalized = _normalizeUrl(rawUrl);
    final uri = Uri.tryParse(normalized);

    if (uri == null ||
        !uri.hasScheme ||
        !(uri.isScheme('http') || uri.isScheme('https'))) {
      return 'Please enter a valid URL for ${_labelForPlatform(platform)}.';
    }

    final host = uri.host.toLowerCase();
    final segments =
        uri.pathSegments.where((segment) => segment.trim().isNotEmpty).toList();

    switch (platform) {
      case 'instagram':
        if (!(host == 'instagram.com' || host == 'www.instagram.com')) {
          return 'Instagram link must be from instagram.com.';
        }
        if (segments.length != 1) {
          return 'Instagram link must point to a profile, not a post or reel.';
        }
        const blocked = {
          'p',
          'reel',
          'reels',
          'stories',
          'explore',
          'tv',
          'accounts',
          'direct',
        };
        if (blocked.contains(segments.first.toLowerCase())) {
          return 'Instagram link must point to a profile.';
        }
        return null;

      case 'facebook':
        if (!(host == 'facebook.com' ||
            host == 'www.facebook.com' ||
            host == 'm.facebook.com')) {
          return 'Facebook link must be from facebook.com.';
        }
        final isProfilePhp = segments.length == 1 &&
            segments.first.toLowerCase() == 'profile.php' &&
            uri.queryParameters['id'] != null &&
            uri.queryParameters['id']!.trim().isNotEmpty;

        final isUsernameProfile = segments.length == 1 &&
            !{
              'watch',
              'share',
              'reel',
              'photo',
              'photos',
              'groups',
              'events',
              'marketplace',
              'gaming',
              'pages',
            }.contains(segments.first.toLowerCase());

        if (!isProfilePhp && !isUsernameProfile) {
          return 'Facebook link must point to a profile.';
        }
        return null;

      case 'youtube':
        if (!(host == 'youtube.com' || host == 'www.youtube.com')) {
          return 'YouTube link must be from youtube.com.';
        }
        final isAtHandle =
            segments.length == 1 && segments.first.startsWith('@');
        final isChannel = segments.length == 2 &&
            {'channel', 'c', 'user'}.contains(segments.first.toLowerCase()) &&
            segments[1].trim().isNotEmpty;

        if (!isAtHandle && !isChannel) {
          return 'YouTube link must point to a channel/profile.';
        }
        return null;

      case 'soundcloud':
        if (!(host == 'soundcloud.com' || host == 'www.soundcloud.com')) {
          return 'SoundCloud link must be from soundcloud.com.';
        }
        if (segments.length != 1) {
          return 'SoundCloud link must point to a profile.';
        }
        const blocked = {
          'discover',
          'stream',
          'you',
          'upload',
          'search',
          'charts',
        };
        if (blocked.contains(segments.first.toLowerCase())) {
          return 'SoundCloud link must point to a profile.';
        }
        return null;

      case 'tiktok':
        if (!(host == 'tiktok.com' ||
            host == 'www.tiktok.com' ||
            host == 'm.tiktok.com')) {
          return 'TikTok link must be from tiktok.com.';
        }
        if (segments.length != 1 || !segments.first.startsWith('@')) {
          return 'TikTok link must point to a profile.';
        }
        return null;

      case 'x':
        if (!(host == 'x.com' ||
            host == 'www.x.com' ||
            host == 'twitter.com' ||
            host == 'www.twitter.com')) {
          return 'X link must be from x.com or twitter.com.';
        }
        if (segments.length != 1) {
          return 'X link must point to a profile.';
        }
        const blocked = {
          'home',
          'explore',
          'search',
          'messages',
          'settings',
          'i',
          'share',
          'compose',
        };
        if (blocked.contains(segments.first.toLowerCase())) {
          return 'X link must point to a profile.';
        }
        return null;

      default:
        return null;
    }
  }

  Map<String, String> _buildExternalLinksMap() {
    final Map<String, String> links = {};
    for (final item in _externalLinks) {
      final url = item.urlController.text.trim();
      if (url.isEmpty) continue;
      links[item.platform] = _normalizeUrl(url);
    }
    return links;
  }

  String _normalizeUrl(String value) {
    if (value.isEmpty) return '';
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);

    if (uri != null && uri.hasScheme) {
      return trimmed;
    }

    return 'https://$trimmed';
  }

  String _labelForPlatform(String platform) {
    return _platformLabels[platform] ?? platform;
  }

  void _setPendingImagePath({
    required ProfileImageType imageType,
    required String filePath,
  }) {
    if (imageType == ProfileImageType.AVATAR) {
      _pendingAvatarImagePath = filePath;
    } else {
      _pendingCoverImagePath = filePath;
    }
  }

  void _clearPendingImagePath(ProfileImageType imageType) {
    if (!mounted) return;
    setState(() {
      if (imageType == ProfileImageType.AVATAR) {
        _pendingAvatarImagePath = null;
      } else {
        _pendingCoverImagePath = null;
      }
    });
  }

  void _syncFormWithState(ProfileState state) {
    final profile = _profileFromState(state);
    if (profile != null && !_hasUnsavedChanges) {
      _applyProfileToForm(profile);
    }
  }

  void _addExternalLink() {
    setState(() {
      _externalLinks.add(
        _EditableExternalLink(
          platform: _supportedPlatforms.first,
          url: '',
          onChanged: _triggerRebuild,
        ),
      );
    });
  }

  Future<void> _removeExternalLink(_EditableExternalLink item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Remove link?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete ${_labelForPlatform(item.platform)} link from your profile?',
          style: const TextStyle(color: Color(0xFF999999)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      item.dispose();
      _externalLinks.remove(item);
    });
  }

  Future<void> _clearAllExternalLinks() async {
    if (_externalLinks.isEmpty) return;

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Clear all links?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will remove all external links from your profile.',
          style: TextStyle(color: Color(0xFF999999)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Clear all',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (shouldClear != true) return;

    setState(() {
      for (final item in _externalLinks) {
        item.dispose();
      }
      _externalLinks.clear();
    });
  }

  Future<String?> _cropImage({
    required String sourcePath,
    required ProfileImageType imageType,
  }) async {
    if (Platform.isWindows) {
      if (!mounted) return null;

      return showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WindowsImageCropDialog(
          sourcePath: sourcePath,
          imageType: imageType,
        ),
      );
    }

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressFormat: ImageCompressFormat.png,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: imageType == ProfileImageType.AVATAR
              ? 'Crop Avatar'
              : 'Crop Cover',
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          backgroundColor: Colors.black,
          activeControlsWidgetColor: const Color(0xFFFF5500),
          lockAspectRatio: imageType == ProfileImageType.AVATAR,
          hideBottomControls: false,
          aspectRatioPresets: imageType == ProfileImageType.AVATAR
              ? [
                  CropAspectRatioPreset.square,
                ]
              : [
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.ratio16x9,
                  CropAspectRatioPreset.ratio4x3,
                ],
        ),
      ],
    );

    return croppedFile?.path;
  }

  Future<String?> _pickWindowsImagePath() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final String? path = result.files.single.path;

    if (path == null || path.trim().isEmpty) {
      throw Exception('Selected image path is invalid.');
    }

    return path;
  }

  Future<void> _onPickImage(ProfileImageType imageType) async {
    try {
      if (widget.pickAndCropImageOverride != null) {
        final String? overridePath =
            await widget.pickAndCropImageOverride!(imageType);
        if (overridePath == null || overridePath.trim().isEmpty || !mounted) {
          return;
        }
        setState(() {
          _setPendingImagePath(imageType: imageType, filePath: overridePath);
        });
        return;
      }

      String? selectedPath;

      if (Platform.isWindows) {
        selectedPath = await _pickWindowsImagePath();
      } else {
        final ImagePicker picker = ImagePicker();

        final XFile? picked = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 100,
        );

        selectedPath = picked?.path;
      }

      if (selectedPath == null || selectedPath.trim().isEmpty || !mounted) {
        return;
      }

      final String? croppedPath = await _cropImage(
        sourcePath: selectedPath,
        imageType: imageType,
      );

      if (croppedPath == null || croppedPath.trim().isEmpty || !mounted) {
        return;
      }

      setState(() {
        _setPendingImagePath(imageType: imageType, filePath: croppedPath);
      });
    } catch (_) {
      if (!mounted) return;
      _showFloatingError('Unable to select image. Please try again.');
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Discard changes?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You have unsaved changes. Leaving will discard them.',
          style: TextStyle(color: Color(0xFF999999)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Keep editing',
              style: TextStyle(color: Color(0xFFAAAAAA)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Discard',
              style: TextStyle(color: Color(0xFFFF5500)),
            ),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  void _showFloatingError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          _syncFormWithState(state);

          if (state is ProfileImageUploading || state is ProfileLoaded) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
          }

          if (state is ProfileUpdateSuccess) {
            context.read<AuthCubit>().refreshCurrentUserSilently();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated'),
                backgroundColor: Color(0xFF1A1A1A),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
          }

          if (state is ProfileImageUploadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade800,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<ProfileCubit>().uploadImage(
                          imageType: state.imageType,
                          filePath: state.filePath,
                        );
                  },
                ),
              ),
            );
          }

          if (state is ProfileUpdateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade800,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isSaving = state is ProfileUpdating;
          final isUploadingAvatar = state is ProfileImageUploading &&
              state.imageType == ProfileImageType.AVATAR;
          final isUploadingCover = state is ProfileImageUploading &&
              state.imageType == ProfileImageType.COVER;

          final currentAvatarUrl = switch (state) {
            ProfileLoaded s => s.profile.avatarUrl,
            ProfileUpdating s => s.currentProfile.avatarUrl,
            ProfileUpdateError s => s.currentProfile.avatarUrl,
            ProfileImageUploading s => s.currentProfile.avatarUrl,
            ProfileUpdateSuccess s => s.updatedProfile.avatarUrl,
            ProfileImageUploadError s => s.currentProfile.avatarUrl,
            _ => _initialProfile.avatarUrl,
          };

          final currentCoverUrl = switch (state) {
            ProfileLoaded s => s.profile.coverPhotoUrl,
            ProfileUpdating s => s.currentProfile.coverPhotoUrl,
            ProfileUpdateError s => s.currentProfile.coverPhotoUrl,
            ProfileImageUploading s => s.currentProfile.coverPhotoUrl,
            ProfileUpdateSuccess s => s.updatedProfile.coverPhotoUrl,
            ProfileImageUploadError s => s.currentProfile.coverPhotoUrl,
            _ => _initialProfile.coverPhotoUrl,
          };

          final canSave = _hasUnsavedChanges && !isSaving;

          return Scaffold(
            backgroundColor: Colors.black,
            appBar: _buildAppBar(
              isSaving: isSaving,
              canSave: canSave,
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EditProfileImageSection(
                      avatarUrl: currentAvatarUrl,
                      coverUrl: currentCoverUrl,
                      localAvatarPath: _pendingAvatarImagePath,
                      localCoverPath: _pendingCoverImagePath,
                      isUploadingAvatar: isUploadingAvatar,
                      isUploadingCover: isUploadingCover,
                      onPickImage: _onPickImage,
                    ),
                    const SizedBox(height: 24),
                    EditProfileTextField(
                      label: 'Display Name',
                      controller: _displayNameController,
                      maxLength: 50,
                      validator: (v) {
                        if (v == null || v.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    _divider(),
                    EditProfileTextField(
                      label: 'City',
                      controller: _cityController,
                      maxLength: 35,
                    ),
                    _divider(),
                    EditProfileCountryPicker(
                      selectedCountry: _selectedCountry,
                      countries: _countries,
                      onCountrySelected: (c) =>
                          setState(() => _selectedCountry = c),
                    ),
                    _divider(),
                    EditProfileTextField(
                      label: 'Website',
                      controller: _websiteController,
                      maxLength: 120,
                    ),
                    _divider(),
                    _buildAccountTypeSection(),
                    _divider(),
                    _buildFavoriteGenresSection(),
                    _divider(),
                    _buildPrivacySection(),
                    _divider(),
                    EditProfileTextField(
                      label: 'Bio',
                      controller: _bioController,
                      maxLength: 160,
                      maxLines: 4,
                    ),
                    _divider(),
                    _buildExternalLinksSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountTypeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Type',
            style: TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<AccountTier>(
            key: ValueKey(_selectedAccountTier),
            initialValue: _selectedAccountTier,
            dropdownColor: const Color(0xFF1A1A1A),
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF333333)),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF333333)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF5500)),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: AccountTier.LISTENER,
                child: Text('Listener'),
              ),
              DropdownMenuItem(
                value: AccountTier.ARTIST,
                child: Text('Artist'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedAccountTier = value);
            },
          ),
          const SizedBox(height: 8),
          Text(
            _selectedAccountTier == AccountTier.ARTIST
                ? 'Artists can access audio uploads.'
                : 'Listener accounts cannot upload tracks.',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return SwitchListTile(
      value: _isPrivate,
      onChanged: (value) => setState(() => _isPrivate = value),
      activeThumbColor: const Color(0xFFFF5500),
      title: const Text(
        'Private account',
        style: TextStyle(color: Colors.white, fontSize: 15),
      ),
      subtitle: Text(
        _isPrivate ? 'Your profile is private.' : 'Your profile is public.',
        style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
      ),
    );
  }

  Widget _buildFavoriteGenresSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Favorite Genres',
            style: TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _favoriteGenreOptions.map((genre) {
              final selected = _selectedFavoriteGenres.contains(genre);
              return FilterChip(
                label: Text(genre),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      if (!_selectedFavoriteGenres.contains(genre)) {
                        _selectedFavoriteGenres = [
                          ..._selectedFavoriteGenres,
                          genre,
                        ];
                      }
                    } else {
                      _selectedFavoriteGenres = _selectedFavoriteGenres
                          .where((item) => item != genre)
                          .toList(growable: false);
                    }
                  });
                },
                selectedColor: const Color(0x33FF5500),
                checkmarkColor: const Color(0xFFFF5500),
                labelStyle: TextStyle(
                  color: selected ? const Color(0xFFFF5500) : Colors.white70,
                ),
                backgroundColor: const Color(0xFF1A1A1A),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFFFF5500)
                      : const Color(0xFF333333),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalLinksSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'External Links',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
              const Spacer(),
              if (_externalLinks.isNotEmpty)
                TextButton(
                  onPressed: _clearAllExternalLinks,
                  child: const Text(
                    'Clear all',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_externalLinks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'No external links added yet.',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 13,
                ),
              ),
            ),
          ..._externalLinks.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ObjectKey(item),
                          initialValue: item.platform,
                          dropdownColor: const Color(0xFF1A1A1A),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Platform',
                            labelStyle: TextStyle(color: Color(0xFF888888)),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF333333)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF333333)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFF5500)),
                            ),
                          ),
                          items: _supportedPlatforms
                              .map(
                                (platform) => DropdownMenuItem<String>(
                                  value: platform,
                                  child: Text(_labelForPlatform(platform)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => item.platform = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _removeExternalLink(item),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: item.urlController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      labelStyle: TextStyle(color: Color(0xFF888888)),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF333333)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF333333)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF5500)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _addExternalLink,
            icon: const Icon(Icons.add, color: Color(0xFFFF5500)),
            label: const Text(
              'Add link',
              style: TextStyle(color: Color(0xFFFF5500)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF5500)),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar({
    required bool isSaving,
    required bool canSave,
  }) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () async {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      title: const Text(
        'Edit profile',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
          child: isSaving
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: canSave ? _onSaveTapped : null,
                  style: TextButton.styleFrom(
                    backgroundColor:
                        canSave ? Colors.white : const Color(0xFF444444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: canSave ? Colors.black : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _divider() => const Divider(
        color: Color(0xFF222222),
        height: 1,
        indent: 16,
        endIndent: 16,
      );
}

bool _listEquals(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (int i = 0; i < first.length; i++) {
    if (first[i] != second[i]) return false;
  }
  return true;
}

class _EditableExternalLink {
  _EditableExternalLink({
    required this.platform,
    required String url,
    required VoidCallback onChanged,
  }) : urlController = TextEditingController(text: url) {
    urlController.addListener(onChanged);
    _listener = onChanged;
  }

  String platform;
  final TextEditingController urlController;
  late final VoidCallback _listener;

  void dispose() {
    urlController.removeListener(_listener);
    urlController.dispose();
  }
}
