// Dart SDK
// Flutter
import 'package:flutter/material.dart';

// Third-party
// Project

/// Reusable inline text field used for Display Name, City, and Bio.
/// Extracted from EditProfilePage.
class EditProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int? maxLength;
  final int maxLines;
  final String? Function(String?)? validator;

  const EditProfileTextField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLength,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
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
              counterStyle:
                  const TextStyle(color: Color(0xFF888888), fontSize: 11),
              errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
