// Dart SDK
// Flutter
import 'package:flutter/material.dart';

// Third-party
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

// Project
import '../../../../core/utils/location_utils.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';
import '../widgets/edit_profile_country_picker.dart';
import '../widgets/edit_profile_image_section.dart';
import '../widgets/edit_profile_text_field.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _bioController;

  String _selectedCountry = '';
  late ProfileEntity _initialProfile;

  static const List<String> _countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Argentina', 'Australia',
    'Austria', 'Bahrain', 'Bangladesh', 'Belgium', 'Brazil',
    'Canada', 'Chile', 'China', 'Colombia', 'Croatia',
    'Czech Republic', 'Denmark', 'Egypt', 'Ethiopia', 'Finland',
    'France', 'Germany', 'Ghana', 'Greece', 'Hungary',
    'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Italy',
    'Japan', 'Jordan', 'Kenya', 'Kuwait', 'Lebanon', 'Libya',
    'Malaysia', 'Mexico', 'Morocco', 'Netherlands', 'New Zealand',
    'Nigeria', 'Norway', 'Oman', 'Pakistan', 'Palestine', 'Peru',
    'Philippines', 'Poland', 'Portugal', 'Qatar', 'Romania', 'Russia',
    'Saudi Arabia', 'Serbia', 'Singapore', 'South Africa', 'South Korea',
    'Spain', 'Sudan', 'Sweden', 'Switzerland', 'Syria', 'Thailand',
    'Tunisia', 'Turkey', 'Ukraine', 'United Arab Emirates',
    'United Kingdom', 'United States', 'Venezuela', 'Vietnam', 'Yemen',
  ];

  bool get _hasUnsavedChanges {
    final currentLocation =
        LocationUtils.build(_cityController.text, _selectedCountry);
    return _displayNameController.text != _initialProfile.displayName ||
        _bioController.text != (_initialProfile.bio ?? '') ||
        currentLocation != _initialProfile.location;
  }

  @override
  void initState() {
    super.initState();
    final cubitState = context.read<ProfileCubit>().state;
    _initialProfile = cubitState is ProfileLoaded
        ? cubitState.profile
        : ProfileEntity(
            id: '',
            displayName: '',
            handle: '',
            accountTier: AccountTier.LISTENER,
            favoriteGenres: const [],
            externalLinks: const {},
            visibility: ProfileVisibility.PUBLIC,
            followersCount: 0,
            followingCount: 0,
          );

    final parsed =
        LocationUtils.parse(_initialProfile.location, _countries);

    _displayNameController =
        TextEditingController(text: _initialProfile.displayName);
    _bioController =
        TextEditingController(text: _initialProfile.bio ?? '');
    _cityController = TextEditingController(text: parsed.city);
    _selectedCountry = parsed.country;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _onSaveTapped() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProfileCubit>().updateProfile(
          UpdateProfileParams(
            displayName: _displayNameController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            location: LocationUtils.build(
                _cityController.text, _selectedCountry),
          ),
        );
  }

  Future<void> _onPickImage(ProfileImageType imageType) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      context.read<ProfileCubit>().uploadImage(
            imageType: imageType,
            filePath: picked.path,
          );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Discard changes?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'You have unsaved changes. Leaving will discard them.',
          style: TextStyle(color: Color(0xFF999999)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing',
                style: TextStyle(color: Color(0xFFAAAAAA))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard',
                style: TextStyle(color: Color(0xFFFF5500))),
          ),
        ],
      ),
    );
    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Using onPopInvokedWithResult instead of deprecated onPopInvoked
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
          if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated'),
                backgroundColor: Color(0xFF1A1A1A),
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.of(context).pop();
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
            _ => _initialProfile.avatarUrl,
          };

          final currentCoverUrl = switch (state) {
            ProfileLoaded s => s.profile.coverPhotoUrl,
            ProfileUpdating s => s.currentProfile.coverPhotoUrl,
            ProfileUpdateError s => s.currentProfile.coverPhotoUrl,
            ProfileImageUploading s => s.currentProfile.coverPhotoUrl,
            ProfileUpdateSuccess s => s.updatedProfile.coverPhotoUrl,
            _ => _initialProfile.coverPhotoUrl,
          };

          return Scaffold(
            backgroundColor: Colors.black,
            appBar: _buildAppBar(isSaving),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Image section (own widget) ─────────────────────
                    EditProfileImageSection(
                      avatarUrl: currentAvatarUrl,
                      coverUrl: currentCoverUrl,
                      isUploadingAvatar: isUploadingAvatar,
                      isUploadingCover: isUploadingCover,
                      onPickImage: _onPickImage,
                    ),
                    const SizedBox(height: 24),

                    // ── Display Name ───────────────────────────────────
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

                    // ── City ───────────────────────────────────────────
                    EditProfileTextField(
                      label: 'City',
                      controller: _cityController,
                      maxLength: 35,
                    ),
                    _divider(),

                    // ── Country (own widget) ───────────────────────────
                    EditProfileCountryPicker(
                      selectedCountry: _selectedCountry,
                      countries: _countries,
                      onCountrySelected: (c) =>
                          setState(() => _selectedCountry = c),
                    ),
                    _divider(),

                    // ── Bio ────────────────────────────────────────────
                    EditProfileTextField(
                      label: 'Bio',
                      controller: _bioController,
                      maxLength: 160,
                      maxLines: 4,
                    ),
                    _divider(),

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

  AppBar _buildAppBar(bool isSaving) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () async {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) Navigator.of(context).pop();
        },
      ),
      title: const Text(
        'Edit profile',
        style: TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
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
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              : GestureDetector(
                  onTap: _onSaveTapped,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
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
