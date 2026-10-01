import 'package:flutter/material.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class AgentShiftBanner extends StatelessWidget {
  const AgentShiftBanner({
    super.key,
    this.agentName = 'Customer Care Agent',
    this.agentId = 'Unavailable',
    this.shift = 'Shift unavailable',
    this.pod = 'Pod unavailable',
  });

  final String agentName;
  final String agentId;
  final String shift;
  final String pod;

  @override
  Widget build(BuildContext context) {
    final agentInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                agentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CustomerCareTextStyles.headlineSm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 76),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: CustomerCareColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  agentId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CustomerCareTextStyles.labelSm.copyWith(
                    color: CustomerCareColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CustomerCareColors.secondary,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'ON-DUTY',
              style: CustomerCareTextStyles.labelSm.copyWith(
                color: CustomerCareColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Text('•', style: CustomerCareTextStyles.labelSm),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                shift,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CustomerCareTextStyles.labelSm.copyWith(
                  color: CustomerCareColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
    final avatar = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CustomerCareColors.surfaceContainerHigh,
        border: Border.all(
          color: CustomerCareColors.primaryContainer.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: Image.network(
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC3W4GIdZAGLdVxWS7_kLtqiX2AiTWYmWsGBri2xY9Gl-YWnSL-KD3LmlgZW8WtuGmpE5kzeIuAvAndvKRc4zoGYOP5jweosVs3eKQx5-QwCVXoTxHvFP7vwJlfXLJYoo_IdWOjVI2re3kbC6iVRjWxumLvpKzxEs7Q4vZEjt3OSQ5YE9WHY3Gtbb31KryzIM2N2VppBby52izn1cmLNsoK-VG610S5CmgsJO3E_7_2e0ImoIB6pK1Q',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.person,
            color: CustomerCareColors.primaryContainer,
            size: 24,
          ),
        ),
      ),
    );
    final podBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CustomerCareColors.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.headset_mic_rounded,
            size: 15,
            color: CustomerCareColors.onSecondaryFixedVariant,
          ),
          const SizedBox(width: 4),
          Text(
            pod,
            style: CustomerCareTextStyles.labelSm.copyWith(
              color: CustomerCareColors.onSecondaryFixedVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: CustomerCareColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 480;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                Row(
                  children: [
                    avatar,
                    const SizedBox(width: 10),
                    Expanded(child: agentInfo),
                  ],
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: podBadge),
              ] else
                Row(
                  children: [
                    avatar,
                    const SizedBox(width: 10),
                    Expanded(child: agentInfo),
                    const SizedBox(width: 10),
                    podBadge,
                  ],
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CustomerCareColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      size: 16,
                      color: CustomerCareColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: CustomerCareTextStyles.bodySm.copyWith(
                            color: CustomerCareColors.onSurfaceVariant,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Mandate: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: CustomerCareColors.onSurface,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Verify caller identity, assess clinical severity, confirm equipment requirements, and hand verified cases to Team Lead.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
