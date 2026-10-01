import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

/// A section label used to group related content on a screen. Only used
/// where content genuinely groups into sections, not as decoration.
class AeroMedSectionHeader extends StatelessWidget {
  const AeroMedSectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: AppTextStyles.bodyStrong.copyWith(fontSize: 13.5)),
          ),
      ],
    );
  }
}
