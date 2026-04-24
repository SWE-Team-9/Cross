import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  final Map<String, dynamic> updateData;
  final bool isMandatory;

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

    return PopScope(
      canPop: !isMandatory,
      child: AlertDialog(
        title: Text(release['title'] ?? 'Update Available'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (release['subtitle'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    release['subtitle'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              if (newFeatures.isNotEmpty) ...[
                _SectionHeader(icon: '✨', label: 'New Features'),
                ..._buildBullets(newFeatures),
                const SizedBox(height: 10),
              ],
              if (improvements.isNotEmpty) ...[
                _SectionHeader(icon: '⚡', label: 'Improvements'),
                ..._buildBullets(improvements),
                const SizedBox(height: 10),
              ],
              if (bugFixes.isNotEmpty) ...[
                _SectionHeader(icon: '🐛', label: 'Bug Fixes'),
                ..._buildBullets(bugFixes),
              ],
            ],
          ),
        ),
        actions: [
          if (!isMandatory)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse(updateData['download_url']);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBullets(List<String> items) {
    return items
        .map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ))
        .toList();
  }
}

class _SectionHeader extends StatelessWidget {
  final String icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$icon $label',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}