import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AeroMedPage extends StatelessWidget {
  const AeroMedPage({super.key, required this.child, this.padded = true});

  final Widget child;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.appBackground, AppColors.secondaryContainer.withValues( alpha: 0.48), AppColors.appBackground],
        ),
      ),
      child: LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth > 900 ? 860.0 : double.infinity;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: padded ? const EdgeInsets.fromLTRB(18, 10, 18, 34) : EdgeInsets.zero,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        );
      },
    ),
    );
  }
}

class AeroMedPageHeader extends StatelessWidget {
  const AeroMedPageHeader({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.pageTitle),
        const SizedBox(height: 6),
        Text(subtitle, style: AppTextStyles.supporting.copyWith(fontSize: 14.5)),
      ],
    );
  }
}

class AeroMedEmptyState extends StatelessWidget {
  const AeroMedEmptyState({super.key, required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center, style: AppTextStyles.supporting),
        ],
      ),
    );
  }
}
