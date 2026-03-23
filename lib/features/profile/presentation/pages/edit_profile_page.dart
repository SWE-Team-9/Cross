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
/// - Bio — inline multiline text field
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _bioController;

  late ProfileEntity _initialProfile;
  String _selectedCountry = '';

  static const List<String> _countries = <String>[
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

  bool get _hasUnsavedChanges {
    return _displayNameController.text.trim() != _initialProfile.displayName ||
        _bioController.text.trim() != (_initialProfile.bio ?? '') ||
        _cityController.text.trim() != (_initialProfile.location ?? '') ||
        _selectedCountry.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    final ProfileState cubitState = context.read<ProfileCubit>().state;

    _initialProfile = cubitState is ProfileLoaded
        ? cubitState.profile
        : ProfileEntity(
            id: '',
            displayName: '',
            handle: '',
            accountTier: AccountTier.LISTENER,
            favoriteGenres: const <String>[],
            externalLinks: const <String, String>{},
            visibility: ProfileVisibility.PUBLIC,
            followersCount: 0,
            followingCount: 0,
          );

    _displayNameController =
        TextEditingController(text: _initialProfile.displayName);
    _cityController = TextEditingController(text: _initialProfile.location ?? '');
    _bioController = TextEditingController(text: _initialProfile.bio ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _onSaveTapped() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String cityText = _cityController.text.trim();
    final String bioText = _bioController.text.trim();
    final String displayNameText = _displayNameController.text.trim();

    final String? locationText = _buildLocation(
      city: cityText,
      country: _selectedCountry,
    );

    context.read<ProfileCubit>().updateProfile(
          UpdateProfileParams(
            displayName: displayNameText,
            bio: bioText.isEmpty ? null : bioText,
            location: locationText,
          ),
        );
  }

  String? _buildLocation({
    required String city,
    required String country,
  }) {
    if (city.isNotEmpty && country.isNotEmpty) {
      return '$city, $country';
    }
    if (city.isNotEmpty) {
      return city;
    }
    if (country.isNotEmpty) {
      return country;
    }
    return null;
  }

  Future<void> _onPickImage(ProfileImageType imageType) async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (picked == null || !mounted) {
      return;
    }

    context.read<ProfileCubit>().uploadImage(
          imageType: imageType,
          filePath: picked.path,
        );
  }

  void _showCountryPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, ScrollController scrollController) {
            return Column(
              children: <Widget>[
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
                    itemBuilder: (_, int index) {
                      final String country = _countries[index];
                      final bool isSelected = country == _selectedCountry;

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
                            ? const Icon(
                                Icons.check,
                                color: Color(0xFFFF5500),
                                size: 18,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCountry = country;
                          });
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
    if (!_hasUnsavedChanges) {
      return true;
    }

    final bool? shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Discard changes?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'You have unsaved changes. Leaving will discard them.',
            style: TextStyle(color: Color(0xFF999999)),
          ),
          actions: <Widget>[
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
        );
      },
    );

    return shouldDiscard ?? false;
  }

  String? _extractAvatarUrl(ProfileState state) {
    return switch (state) {
      ProfileLoaded s => s.profile.avatarUrl,
      ProfileUpdating s => s.currentProfile.avatarUrl,
      ProfileUpdateError s => s.currentProfile.avatarUrl,
      ProfileImageUploading s => s.currentProfile.avatarUrl,
      ProfileUpdateSuccess s => s.updatedProfile.avatarUrl,
      _ => _initialProfile.avatarUrl,
    };
  }

  String? _extractCoverUrl(ProfileState state) {
    return switch (state) {
      ProfileLoaded s => s.profile.coverPhotoUrl,
      ProfileUpdating s => s.currentProfile.coverPhotoUrl,
      ProfileUpdateError s => s.currentProfile.coverPhotoUrl,
      ProfileImageUploading s => s.currentProfile.coverPhotoUrl,
      ProfileUpdateSuccess s => s.updatedProfile.coverPhotoUrl,
      _ => _initialProfile.coverPhotoUrl,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }

        final bool shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (BuildContext context, ProfileState state) {
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
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (BuildContext context, ProfileState state) {
          final bool isSaving = state is ProfileUpdating;
          final bool isUploadingAvatar = state is ProfileImageUploading &&
              state.imageType == ProfileImageType.AVATAR;
          final bool isUploadingCover = state is ProfileImageUploading &&
              state.imageType == ProfileImageType.COVER;

          final String? currentAvatarUrl = _extractAvatarUrl(state);
          final String? currentCoverUrl = _extractCoverUrl(state);

          return Scaffold(
            backgroundColor: Colors.black,
            appBar: _buildAppBar(isSaving),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildCoverAndAvatar(
                      avatarUrl: currentAvatarUrl,
                      coverUrl: currentCoverUrl,
                      isUploadingAvatar: isUploadingAvatar,
                      isUploadingCover: isUploadingCover,
                    ),
                    const SizedBox(height: 24),
                    _buildInlineField(
                      label: 'Display Name',
                      controller: _displayNameController,
                      maxLength: 50,
                      validator: (String? value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    _buildDivider(),
                    _buildInlineField(
                      label: 'City',
                      controller: _cityController,
                      maxLength: 35,
                    ),
                    _buildDivider(),
                    _buildCountryRow(),
                    _buildDivider(),
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

  AppBar _buildAppBar(bool isSaving) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () async {
          final bool shouldPop = await _onWillPop();
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
      actions: <Widget>[
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
                      horizontal: 20,
                      vertical: 8,
                    ),
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
        children: <Widget>[
          GestureDetector(
            onTap: isUploadingCover
                ? null
                : () => _onPickImage(ProfileImageType.COVER),
            child: Container(
              width: double.infinity,
              height: 140,
              color: const Color(0xFFAAAAAA),
              child: coverUrl != null
                  ? Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
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
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 140,
                child: ColoredBox(
                  color: Colors.black38,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 16,
            child: Stack(
              children: <Widget>[
                CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFFB8CDE8),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 52,
                          color: Color(0xFF8AAECF),
                        )
                      : null,
                ),
                if (isUploadingAvatar)
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
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
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
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
        children: <Widget>[
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterStyle: TextStyle(
                color: Color(0xFF888888),
                fontSize: 11,
              ),
              errorStyle: TextStyle(
                color: Colors.red,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryRow() {
    return InkWell(
      onTap: _showCountryPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                    style: const TextStyle(
                      color: Colors.white,
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
  Widget _buildDivider() {
    return const Divider(
      color: Color(0xFF222222),
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}