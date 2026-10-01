import 'package:flutter/material.dart';
import '../theme/ambulance_first_theme.dart';

/// Form Input Field for Ambulance First Customer Portal
class AmbulanceFirstTextInput extends StatelessWidget {
  const AmbulanceFirstTextInput({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.isRequired = false,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AmbulanceFirstTypography.labelMd(color: AmbulanceFirstColors.onSurface).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: AmbulanceFirstTypography.labelMd(color: AmbulanceFirstColors.medicalCrimson),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onChanged: onChanged,
          validator: validator,
          style: AmbulanceFirstTypography.bodyMd(color: AmbulanceFirstColors.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

/// Styled Dropdown Form Field for Ambulance First
class AmbulanceFirstDropdown<T> extends StatelessWidget {
  const AmbulanceFirstDropdown({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
    this.validator,
    this.isRequired = false,
    this.hintText,
  });

  final String label;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool isRequired;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AmbulanceFirstTypography.labelMd(color: AmbulanceFirstColors.onSurface).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: AmbulanceFirstTypography.labelMd(color: AmbulanceFirstColors.medicalCrimson),
              ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          validator: validator,
          hint: hintText != null ? Text(hintText!, style: AmbulanceFirstTypography.bodyMd(color: AmbulanceFirstColors.textMuted)) : null,
          style: AmbulanceFirstTypography.bodyMd(color: AmbulanceFirstColors.onSurface),
          icon: const Icon(Icons.arrow_drop_down, color: AmbulanceFirstColors.onSurfaceVariant),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
