import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
export '../services/update_service.dart';
import '../services/update_service.dart';
import '../services/apk_installer_service.dart';

class UpdateDialog extends StatelessWidget {
  final Map<String, dynamic> updateData;
  final String downloadUrl;
  final UpdateType updateType;
  final bool isMandatory;

  // Brand colors
  static const _orange = Color(0xFFFF5500);
  static const _cardBg = Color(0xFF1A1A1A);
  static const _textSecondary = Color(0xFFCCCCCC);
  static const _divider = Color(0xFF333333);

  const UpdateDialog({
    super.key,
    required this.updateData,
    required this.downloadUrl,
    required this.updateType,
    this.isMandatory = false,
  });

  @override
  Widget build(BuildContext context) {
    // Normalize release payloads
    dynamic rawRelease = updateData['release'];

    if (rawRelease == null && updateData['releases'] is List) {
      final list = updateData['releases'] as List;
      if (list.isNotEmpty) rawRelease = list.first;
    }

    Map<String, dynamic> release;
    if (rawRelease is Map<String, dynamic>) {
      release = rawRelease;
    } else if (rawRelease is String) {
      final decoded = rawRelease.trim();
      if (decoded.startsWith('{') || decoded.startsWith('[')) {
        try {
          final parsed = jsonDecode(decoded);
          if (parsed is Map<String, dynamic>) {
            release = parsed;
          } else if (parsed is List &&
              parsed.isNotEmpty &&
              parsed.first is Map) {
            release = Map<String, dynamic>.from(parsed.first as Map);
          } else {
            release = <String, dynamic>{};
          }
        } catch (_) {
          release = <String, dynamic>{'notes': rawRelease};
        }
      } else {
        release = <String, dynamic>{'notes': rawRelease};
      }
    } else {
      release = <String, dynamic>{};
    }

    List<String> extractList(Map<String, dynamic> src, List<String> keys) {
      for (final k in keys) {
        final v = src[k];
        if (v == null) continue;
        if (v is List)
          return v
              .map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
        if (v is String) {
          final s = v.trim();
          if (s.isEmpty) return <String>[];
          return s
              .split(RegExp(r"\r?\n"))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
      return <String>[];
    }

    final newFeatures = extractList(release, [
      'new_features',
      'newFeatures',
      'whats_new',
      "what's_new",
      'features',
      'notes',
      'release_notes',
      'description',
      'body'
    ]);
    final improvements = extractList(release,
        ['improvements', 'improvement', 'improvements_list', 'enhancements']);
    final bugFixes = extractList(
        release, ['bug_fixes', 'bugFixes', 'fixes', 'bugs', 'patches']);
    final hasContent = newFeatures.isNotEmpty ||
        improvements.isNotEmpty ||
        bugFixes.isNotEmpty;

    return Dialog(
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
            _Header(release: release, isMandatory: isMandatory),
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
                            color: _orange),
                        const SizedBox(height: 6),
                        ..._buildBullets(newFeatures),
                        const SizedBox(height: 14),
                      ],
                      if (improvements.isNotEmpty) ...[
                        _SectionHeader(
                            icon: Icons.bolt_rounded,
                            label: 'Improvements',
                            color: const Color(0xFF4FC3F7)),
                        const SizedBox(height: 6),
                        ..._buildBullets(improvements),
                        const SizedBox(height: 14),
                      ],
                      if (bugFixes.isNotEmpty) ...[
                        _SectionHeader(
                            icon: Icons.bug_report_rounded,
                            label: 'Bug Fixes',
                            color: const Color(0xFF81C784)),
                        const SizedBox(height: 6),
                        ..._buildBullets(bugFixes),
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
              ),
            const Divider(color: _divider, height: 1, thickness: 1),
            _Actions(
                isMandatory: isMandatory,
                downloadUrl: downloadUrl,
                updateType: updateType),
          ],
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
                    color: const Color(0x4DFF5500),
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
          Text(
            release['title'] ?? 'Update Available',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          if (release['subtitle'] != null)
            Text(
              release['subtitle'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 13,
              ),
            ),
          if (isMandatory) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x26FF5500),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0x66FF5500),
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader(
      {required this.icon, required this.label, required this.color});

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

class _Actions extends StatefulWidget {
  final bool isMandatory;
  final String downloadUrl;
  final UpdateType updateType;

  const _Actions(
      {required this.isMandatory,
      required this.downloadUrl,
      required this.updateType});

  @override
  State<_Actions> createState() => _ActionsState();
}

class _ActionsState extends State<_Actions> {
  double? _progress;
  bool _hasError = false;
  String _errorMessage = '';

  Future<void> _onUpdateTap() async {
    switch (widget.updateType) {
      case UpdateType.inApp:
        await _startInAppDownload();
        break;
      case UpdateType.browser:
      case UpdateType.store:
        final url = Uri.parse(widget.downloadUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open update link.')));
        }
        break;
      case UpdateType.unsupported:
        break;
    }
  }

  Future<void> _startInAppDownload() async {
    setState(() {
      _progress = 0.0;
      _hasError = false;
    });

    await ApkInstallerService.downloadAndInstall(
      downloadUrl: widget.downloadUrl,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
      onError: (e) {
        if (mounted)
          setState(() {
            _progress = null;
            _hasError = true;
            _errorMessage = e;
          });
      },
    );
  }

  String get _buttonLabel {
    switch (widget.updateType) {
      case UpdateType.inApp:
        return 'Update Now';
      case UpdateType.browser:
        return 'Download Update';
      case UpdateType.store:
        return 'Open App Store';
      case UpdateType.unsupported:
        return 'Update';
    }
  }

  IconData get _buttonIcon {
    switch (widget.updateType) {
      case UpdateType.inApp:
        return Icons.system_update_rounded;
      case UpdateType.browser:
        return Icons.download_rounded;
      case UpdateType.store:
        return Icons.store_rounded;
      default:
        return Icons.update_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: widget.updateType == UpdateType.inApp && _progress != null
                ? _ProgressButton(progress: _progress!)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFF5500), Color(0xFFFF7A00)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _onUpdateTap,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_buttonIcon, size: 18),
                          const SizedBox(width: 8),
                          Text(_buttonLabel,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
          ),
          if (_hasError) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFFF5252), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(_errorMessage,
                      style: const TextStyle(
                          color: Color(0xFFFF5252), fontSize: 12)),
                ),
              ],
            ),
          ],
          if (!widget.isMandatory) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF999999),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed:
                    widget.updateType == UpdateType.inApp && _progress != null
                        ? null
                        : () => Navigator.pop(context),
                child: const Text('Maybe Later',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressButton extends StatelessWidget {
  final double progress;
  const _ProgressButton({required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF222222),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF333333))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFFFF5500), Color(0xFFFF7A00)]),
                ),
              ),
            ),
            Center(
              child: Text(
                  percent < 100 ? 'Downloading... $percent%' : 'Installing...',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
