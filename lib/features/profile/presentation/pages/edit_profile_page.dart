// Dart SDK
// Flutter
import 'package:flutter/material.dart';

// Third-party
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

// Project
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../bloc/profile_cubit.dart';
import '../bloc/profile_state.dart';

/// T2.4 — Edit Profile Page.
/// Matches real SoundCloud edit profile UI:
/// - Cover photo banner + overlapping avatar
/// - Back arrow + white pill Save button
/// - Display Name — inline text field
/// - City — inline text field
/// - Country — tappable row that opens a bottom sheet picker
/// - Bio — inline multiline text field (not a navigation row)
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

  // Full country list for the picker
  static const List<String> _countries = [
    'Afghanistan', 'Albania', 'Algeria', 'Argentina', 'Australia',
    'Austria', 'Bahrain', 'Bangladesh', 'Belgium', 'Brazil',
    'Canada', 'Chile', 'China', 'Colombia', 'Croatia',
    'Czech Republic', 'Denmark', 'Egypt', 'Ethiopia', 'Finland',
    'France', 'Germany', 'Ghana', 'Greece', 'Hungary',
    'India', 'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Italy', 'Japan', 'Jordan', 'Kenya',
    'Kuwait', 'Lebanon', 'Libya', 'Malaysia', 'Mexico',
    'Morocco', 'Netherlands', 'New Zealand', 'Nigeria', 'Norway',
    'Oman', 'Pakistan', 'Palestine', 'Peru', 'Philippines',
    'Poland', 'Portugal', 'Qatar', 'Romania', 'Russia',
    'Saudi Arabia', 'Serbia', 'Singapore', 'South Africa', 'South Korea',
    'Spain', 'Sudan', 'Sweden', 'Switzerland', 'Syria',
    'Thailand', 'Tunisia', 'Turkey', 'Ukraine', 'United Arab Emirates',
    'United Kingdom', 'United States', 'Venezuela', 'Vietnam', 'Yemen',
  ];

  bool get _hasUnsavedChanges =>
      _displayNameController.text != _initialProfile.displayName ||
      _bioController.text != (_initialProfile.bio ?? '') ||
      _cityController.text != (_initialProfile.location ?? '') ||
      _selectedCountry != '';

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

    _displayNameController =
        TextEditingController(text: _initialProfile.displayName);
    _bioController =
        TextEditingController(text: _initialProfile.bio ?? '');
    _cityController =
        TextEditingController(text: _initialProfile.location ?? '');
    _selectedCountry = '';
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _onSaveTapped() async {
    if (!_formKey.currentState!.validate()) return;

    // Combine city + country into location string if both provided
    final cityText = _cityController.text.trim();
    final locationText = _selectedCountry.isNotEmpty && cityText.isNotEmpty
        ? '$cityText, $_selectedCountry'
        : cityText.isNotEmpty
            ? cityText
            : _selectedCountry.isNotEmpty
                ? _selectedCountry
                : null;

    context.read<ProfileCubit>().updateProfile(
          UpdateProfileParams(
            displayName: _displayNameController.text.trim(),
            bio: _bioController.text.trim().isEmpty
                ? null
                : _bioController.text.trim(),
            location: locationText,
          ),
        );
  }

  Future<void> _onPickImage(ProfileImageType imageType) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
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

  /// Opens a bottom sheet with a scrollable list of countries.
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF555555),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Select Country',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(color: Color(0xFF333333), height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _countries.length,
                    itemBuilder: (_, i) {
                      final country = _countries[i];
                      final isSelected = country == _selectedCountry;
                      return ListTile(
                        title: Text(
                          country,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFFFF5500)
                                : Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check,
                                color: Color(0xFFFF5500), size: 18)
                            : null,
                        onTap: () {
                          setState(() => _selectedCountry = country);
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) Navigator.of(context).pop();
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
                    _buildCoverAndAvatar(
                      avatarUrl: currentAvatarUrl,
                      coverUrl: currentCoverUrl,
                      isUploadingAvatar: isUploadingAvatar,
                      isUploadingCover: isUploadingCover,
                    ),
                    const SizedBox(height: 24),

                    // Display Name — inline field
                    _buildInlineField(
                      label: 'Display Name',
                      controller: _displayNameController,
                      maxLength: 50,
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    _buildDivider(),

                    // City — inline field
                    _buildInlineField(
                      label: 'City',
                      controller: _cityController,
                      maxLength: 35,
                    ),
                    _buildDivider(),

                    // Country — tappable row → bottom sheet picker
                    _buildCountryRow(),
                    _buildDivider(),

                    // Bio — inline multiline text field
                    _buildInlineField(
                      label: 'Bio',
                      controller: _bioController,
                      maxLength: 160,
                      maxLines: 4,
                    ),
                    _buildDivider(),

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

  // ── AppBar ─────────────────────────────────────────────────────────────────

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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Cover + Avatar ─────────────────────────────────────────────────────────

  Widget _buildCoverAndAvatar({
    required String? avatarUrl,
    required String? coverUrl,
    required bool isUploadingAvatar,
    required bool isUploadingCover,
  }) {
    return SizedBox(
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover banner
          GestureDetector(
            onTap: isUploadingCover
                ? null
                : () => _onPickImage(ProfileImageType.COVER),
            child: Container(
              width: double.infinity,
              height: 140,
              color: const Color(0xFFAAAAAA),
              child: coverUrl != null
                  ? Image.network(coverUrl, fit: BoxFit.cover)
                  : null,
            ),
          ),
          // Camera icon on cover
          if (!isUploadingCover)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => _onPickImage(ProfileImageType.COVER),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          if (isUploadingCover)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 140,
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          // Avatar overlapping cover at bottom-left
          Positioned(
            bottom: 0,
            left: 16,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFFB8CDE8),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person,
                          size: 52, color: Color(0xFF8AAECF))
                      : null,
                ),
                if (isUploadingAvatar)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => _onPickImage(ProfileImageType.AVATAR),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Inline text field (Display Name, City, Bio) ───────────────────────────

  Widget _buildInlineField({
    required String label,
    required TextEditingController controller,
    int? maxLength,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            maxLength: maxLength,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterStyle: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 11,
              ),
              errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ── Country row — taps to open bottom sheet ────────────────────────────────

  Widget _buildCountryRow() {
    return InkWell(
      onTap: _showCountryPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Country',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedCountry.isEmpty ? 'Country' : _selectedCountry,
                    style: TextStyle(
                      color: _selectedCountry.isEmpty
                          ? Colors.white
                          : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Divider ────────────────────────────────────────────────────────────────

  Widget _buildDivider() {
    return const Divider(
      color: Color(0xFF222222),
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}