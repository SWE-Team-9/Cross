
import 'package:flutter/material.dart';

// Third-party
// Project
import '../../domain/repositories/profile_repository.dart';

/// Cover photo banner + overlapping avatar with upload overlays.
/// Extracted from EditProfilePage to keep the page file small.
/// Calls onPickImage when user taps avatar or cover camera button.
class EditProfileImageSection extends StatelessWidget {
  final String? avatarUrl;
  final String? coverUrl;
  final bool isUploadingAvatar;
  final bool isUploadingCover;
  final void Function(ProfileImageType) onPickImage;

  const EditProfileImageSection({
    super.key,
    required this.avatarUrl,
    required this.coverUrl,
    required this.isUploadingAvatar,
    required this.isUploadingCover,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover banner
          GestureDetector(
            onTap: isUploadingCover
                ? null
                : () => onPickImage(ProfileImageType.COVER),
            child: Container(
              width: double.infinity,
              height: 140,
              color: const Color(0xFFAAAAAA),
              child: coverUrl != null
                  ? Image.network(coverUrl!, fit: BoxFit.cover)
                  : null,
            ),
          ),
          if (!isUploadingCover)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => onPickImage(ProfileImageType.COVER),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          if (isUploadingCover)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 140,
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          // Avatar overlapping cover
          Positioned(
            bottom: 0,
            left: 16,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: const Color(0xFFB8CDE8),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
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
                            strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  )
                else
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => onPickImage(ProfileImageType.AVATAR),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.camera_alt,
                              color: Colors.white, size: 22),
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
}