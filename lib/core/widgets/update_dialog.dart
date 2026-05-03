import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  final Map<String, dynamic> updateData;
  final bool isMandatory;

  // SoundCloud brand colors
  static const _orange = Color(0xFFFF5500);
  // static const _darkBg = Color(0xFF111111);
  static const _cardBg = Color(0xFF1A1A1A);
  // static const _surfaceBg = Color(0xFF222222);
  // static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFCCCCCC);
  // static const _textMuted = Color(0xFF999999);
  static const _divider = Color(0xFF333333);

  const UpdateDialog({
    super.key,
    required this.updateData,
    this.isMandatory = false,
  });

  @override
  Widget build(BuildContext context) {
    final release = updateData['release'] as Map<String, dynamic>;
    final newFeatures = List<String>.from(release['new_features'] ?? []);
    final improvements = List<String>.from(release['improvements'] ?? []);
    final bugFixes = List<String>.from(release['bug_fixes'] ?? []);
    final hasContent = newFeatures.isNotEmpty ||
        improvements.isNotEmpty ||
        bugFixes.isNotEmpty;

    return PopScope(
      canPop: !isMandatory,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _divider, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────
              _Header(release: release, isMandatory: isMandatory),

              // ── Content ─────────────────────────────────────
              if (hasContent)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (newFeatures.isNotEmpty) ...[
                          _SectionHeader(
                            icon: Icons.auto_awesome_rounded,
                            label: 'New Features',
                            color: _orange,
                          ),
                          const SizedBox(height: 6),
                          ..._buildBullets(newFeatures),
                          const SizedBox(height: 14),
                        ],
                        if (improvements.isNotEmpty) ...[
                          _SectionHeader(
                            icon: Icons.bolt_rounded,
                            label: 'Improvements',
                            color: const Color(0xFF4FC3F7),
                          ),
                          const SizedBox(height: 6),
                          ..._buildBullets(improvements),
                          const SizedBox(height: 14),
                        ],
                        if (bugFixes.isNotEmpty) ...[
                          _SectionHeader(
                            icon: Icons.bug_report_rounded,
                            label: 'Bug Fixes',
                            color: const Color(0xFF81C784),
                          ),
                          const SizedBox(height: 6),
                          ..._buildBullets(bugFixes),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                ),

              // ── Divider ─────────────────────────────────────
              const Divider(color: _divider, height: 1, thickness: 1),

              // ── Actions ─────────────────────────────────────
              _Actions(
                isMandatory: isMandatory,
                downloadUrl: updateData['download_url'] as String,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBullets(List<String> items) {
    return items
        .map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5, right: 8),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: _orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Map<String, dynamic> release;
  final bool isMandatory;

  const _Header({required this.release, required this.isMandatory});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          // SoundCloud logo mark + update badge
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF5500).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.cloud_rounded,
                  color: Color(0xFFFF5500),
                  size: 32,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5500),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            release['title'] ?? 'Update Available',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          if (release['subtitle'] != null)
            Text(
              release['subtitle'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 13,
              ),
            ),

          // Mandatory badge
          if (isMandatory) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5500).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF5500).withOpacity(0.4),
                ),
              ),
              child: const Text(
                'Required Update',
                style: TextStyle(
                  color: Color(0xFFFF5500),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(color: Color(0xFF333333), height: 1, thickness: 1),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Actions ───────────────────────────────────────────────────────────────────

class _Actions extends StatelessWidget {
  final bool isMandatory;
  final String downloadUrl;

  const _Actions({required this.isMandatory, required this.downloadUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        children: [
          // Update Now button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5500), Color(0xFFFF7A00)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final url = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.system_update_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Update Now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Later button
          if (!isMandatory) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF999999),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
