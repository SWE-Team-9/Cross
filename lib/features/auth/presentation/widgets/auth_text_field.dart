import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF8B8B8B),
          fontSize: 18,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4C4C4E),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4C4C4E),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFFF6A00),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}