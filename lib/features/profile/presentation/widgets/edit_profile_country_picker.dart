// Dart SDK
// Flutter
import 'package:flutter/material.dart';

// Third-party
// Project

/// Tappable country row + bottom sheet picker.
/// Extracted from EditProfilePage.
class EditProfileCountryPicker extends StatelessWidget {
  final String selectedCountry;
  final List<String> countries;
  final ValueChanged<String> onCountrySelected;

  const EditProfileCountryPicker({
    super.key,
    required this.selectedCountry,
    required this.countries,
    required this.onCountrySelected,
  });

  void _show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF555555),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      onCountrySelected('');
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Clear',
                        style: TextStyle(
                            color: Color(0xFFFF5500), fontSize: 14)),
                  ),
                  const Text('Select Country',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: Color(0xFF888888), fontSize: 14)),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF333333), height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: countries.length,
                itemBuilder: (_, i) {
                  final country = countries[i];
                  final isSelected = country == selectedCountry;
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
                      onCountrySelected(country);
                      Navigator.of(sheetContext).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _show(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Country',
                      style: TextStyle(
                          color: Color(0xFF888888), fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    selectedCountry.isEmpty
                        ? 'Not specified'
                        : selectedCountry,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}