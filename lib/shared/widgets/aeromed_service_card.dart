import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text_styles.dart';
import './aeromed_card.dart';


class AeroMedServiceCard extends StatelessWidget {
  const AeroMedServiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AeroMedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      borderRadius: AppRadius.card,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headlineSmall.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing ??
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
              ),
        ],
      ),
    );
  }
}

/// Rich Ambulance Fleet Option Card derived from Stitch screen #358e131185874356b08aacd6b3d4d8ce
class AeroMedFleetCard extends StatelessWidget {
  const AeroMedFleetCard({
    super.key,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.eta,
    required this.equipment,
    required this.selected,
    required this.onTap,
    this.isRecommended = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final double price;
  final String eta;
  final List<String> equipment;
  final bool selected;
  final VoidCallback onTap;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceContainerHigh.withValues( alpha: 0.78) : AppColors.surfaceContainer.withValues( alpha: 0.64),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outlineVariant.withValues( alpha: 0.7),
              width: selected ? 1.8 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(color: AppColors.primary.withValues( alpha: 0.20), blurRadius: 24, offset: const Offset(0, 8)),
                    BoxShadow(color: AppColors.white.withValues( alpha: 0.80), blurRadius: 14, offset: const Offset(-5, -5)),
                  ]
                : [
                    BoxShadow(color: AppColors.primaryDark.withValues( alpha: 0.09), blurRadius: 18, offset: const Offset(7, 7)),
                    BoxShadow(color: AppColors.white.withValues( alpha: 0.86), blurRadius: 16, offset: const Offset(-6, -6)),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top header with radio check + title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected ? AppColors.primary : AppColors.surfaceContainerHighest,
                            border: Border.all(
                              color: selected ? AppColors.primary : AppColors.outline,
                              width: 2,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: selected ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Equipment chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: equipment.map((eq) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary.withValues( alpha: 0.3)
                                  : AppColors.outlineVariant.withValues( alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 12,
                                color: selected ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                eq,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Availability and request-only status. Pricing is calculated after verification.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.radar_rounded,
                                size: 16,
                                color: selected ? AppColors.primary : AppColors.secondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Available • $eta',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: selected ? AppColors.primary : AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'REQUEST QUOTE AFTER VERIFICATION',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: selected ? AppColors.primary : AppColors.textMuted,
                              letterSpacing: 0.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Most Recommended Badge
        if (isRecommended)
          Positioned(
            top: -10,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: mintGlow(opacity: 0.4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.recommend_rounded, size: 14, color: AppColors.onPrimary),
                  const SizedBox(width: 4),
                  Text(
                    'MOST RECOMMENDED',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
