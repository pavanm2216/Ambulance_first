import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import './aero_surface.dart';

/// A thin, consistent wrapper around [TextFormField] so every input on
/// the booking form (and beyond) shares the same label/icon/validation
/// presentation — styling itself comes from the app's InputDecorationTheme.
class AeroMedTextField extends StatelessWidget {
  const AeroMedTextField({
    super.key,
    required this.label,
    this.controller,
    this.icon,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.hintText,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final TextEditingController? controller;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hintText;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AeroNeumorphic(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      ),
    );
  }
}
