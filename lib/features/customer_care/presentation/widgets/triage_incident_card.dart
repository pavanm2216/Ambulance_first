import 'package:flutter/material.dart';

import '../../../../core/models/customer_care_case.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class TriageIncidentCard extends StatelessWidget {
  const TriageIncidentCard({
    super.key,
    required this.caseItem,
    required this.onCallVerify,
    required this.onViewDetails,
    this.onSendToTeamLead,
    this.onCallPhone,
  });

  final CustomerCareCase caseItem;
  final VoidCallback onCallVerify;
  final VoidCallback onViewDetails;
  final VoidCallback? onSendToTeamLead;
  final VoidCallback? onCallPhone;

  Color get _urgencyAccentColor {
    if (caseItem.isCodeRed) return CustomerCareColors.error;
    if (caseItem.status.toUpperCase() == 'VERIFIED') {
      return CustomerCareColors.secondary;
    }
    if (caseItem.pediatric) return CustomerCareColors.tertiary;
    if (caseItem.priority == 'HIGH') return CustomerCareColors.warning;
    return CustomerCareColors.primaryContainer;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _urgencyAccentColor;
    final status = caseItem.status.toUpperCase();
    final isVerified = status == 'VERIFIED';
    final isSentToTeamLead = status == 'SENT_TO_TEAM_LEAD';
    final isDraft = caseItem.isDraft;

    return Container(
      decoration: BoxDecoration(
        color: CustomerCareColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CustomerCareColors.outlineVariant,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Urgency Color Bar
            Container(width: 5, color: accent),
            // Card Body Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Booking ID + Timestamp + Urgency Pill
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                          children: [
                              Flexible(
                                child: Text(
                                  '#${caseItem.id}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CustomerCareTextStyles.labelLg.copyWith(
                                    color: CustomerCareColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CustomerCareColors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Updated ${_formatTimestamp(caseItem.updatedAt.isEmpty ? caseItem.createdAt : caseItem.updatedAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CustomerCareTextStyles.labelSm.copyWith(
                                      color: CustomerCareColors.onSurfaceVariant,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: _buildStatusBadge(accent, isVerified),
                          ),
                        ),
                      ],
                    ),
                    if (isDraft) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: CustomerCareColors.warningContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'DRAFT — CUSTOMER IS FILLING DETAILS',
                          style: CustomerCareTextStyles.labelSm.copyWith(
                            color: CustomerCareColors.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ] else if (caseItem.isSubmitted) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Text(
                            'PENDING VERIFICATION',
                            style: CustomerCareTextStyles.labelSm.copyWith(
                              color: CustomerCareColors.warning,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (caseItem.submittedAt.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Submitted ${_formatTimestamp(caseItem.submittedAt)}',
                              style: CustomerCareTextStyles.labelSm.copyWith(
                                color: CustomerCareColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 1),
                    Text(
                      caseItem.dispatchTier,
                      style: CustomerCareTextStyles.labelSm.copyWith(
                        color: CustomerCareColors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Caller Information Strip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: CustomerCareColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: CustomerCareColors
                                        .surfaceContainerHighest,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 15,
                                    color: CustomerCareColors.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${caseItem.customerName} (${caseItem.relationship})',
                                        style: CustomerCareTextStyles.bodySm
                                            .copyWith(
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  CustomerCareColors.onSurface,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        caseItem.mobileNumber,
                                        style: CustomerCareTextStyles.labelSm
                                            .copyWith(
                                              color: CustomerCareColors
                                                  .primaryContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: onCallPhone ?? onCallVerify,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: CustomerCareColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.call,
                                    size: 13,
                                    color: CustomerCareColors
                                        .onSecondaryFixedVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Call',
                                    style: CustomerCareTextStyles.labelSm
                                        .copyWith(
                                          color: CustomerCareColors
                                              .onSecondaryFixedVariant,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Patient & Clinical Scenario
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${caseItem.patientName}, ${caseItem.age}${caseItem.gender.isNotEmpty ? caseItem.gender[0].toUpperCase() : ""}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CustomerCareTextStyles.bodyLg.copyWith(
                              fontWeight: FontWeight.w700,
                              color: CustomerCareColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CustomerCareColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 130),
                            child: Text(
                              caseItem.ambulanceCategory.isNotEmpty
                                  ? caseItem.ambulanceCategory
                                  : caseItem.serviceCategory == 'AIR'
                                  ? 'Air Medevac'
                                  : (caseItem.icu
                                        ? 'ACLS Unit'
                                        : 'Patient Transport'),
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
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          caseItem.isCodeRed
                              ? Icons.monitor_heart_rounded
                              : (caseItem.pediatric
                                    ? Icons.child_care
                                    : Icons.monitor_heart),
                          size: 14,
                          color: caseItem.isCodeRed
                              ? CustomerCareColors.error
                              : CustomerCareColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            caseItem.condition,
                            style: CustomerCareTextStyles.bodySm.copyWith(
                              color: caseItem.isCodeRed
                                  ? CustomerCareColors.error
                                  : CustomerCareColors.onSurfaceVariant,
                              fontWeight: caseItem.isCodeRed
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (caseItem.specialInstructions.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Customer notes: ${caseItem.specialInstructions}',
                        style: CustomerCareTextStyles.bodySm.copyWith(
                          color: CustomerCareColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Requirement Badges
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        if (caseItem.oxygen)
                          _buildReqBadge(
                            'O2: ${caseItem.oxygenFlow != null ? "${caseItem.oxygenFlow!.toInt()}L" : "High Flow"}',
                          ),
                        if (caseItem.icu) _buildReqBadge('ICU Setup'),
                        if (caseItem.ventilator)
                          _buildReqBadge('Ventilator Ready'),
                        if (caseItem.cardiacMonitor)
                          _buildReqBadge('Cardiac Monitor'),
                        if (caseItem.doctor) _buildReqBadge('Doctor Escort'),
                        if (caseItem.pediatric)
                          _buildReqBadge('Pediatric Incubator'),
                        if (caseItem.emt) _buildReqBadge('Lead Paramedic'),
                        if (caseItem.attendant) _buildReqBadge('Attendant'),
                        if (caseItem.stretcher) _buildReqBadge('Stretcher'),
                        if (caseItem.wheelchair) _buildReqBadge('Wheelchair'),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Route Telemetry
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: CustomerCareColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: CustomerCareColors.outlineVariant,
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_hospital_outlined,
                            size: 14,
                            color: CustomerCareColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              caseItem.pickupAddress,
                              style: CustomerCareTextStyles.bodySm.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 12,
                              color: CustomerCareColors.outline,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              caseItem.destinationHospital.isNotEmpty
                                  ? caseItem.destinationHospital
                                  : caseItem.destinationAddress,
                              style: CustomerCareTextStyles.bodySm.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              caseItem.distanceKm > 0
                                  ? '${caseItem.distanceKm} km'
                                  : 'Route unavailable',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CustomerCareTextStyles.labelSm.copyWith(
                                color: CustomerCareColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Actions
                    if (isVerified)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onSendToTeamLead,
                              icon: const Icon(
                                Icons.checklist_rtl_rounded,
                                size: 16,
                              ),
                              label: const Text('Send to Team Lead (Handover)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    CustomerCareColors.primaryContainer,
                                foregroundColor: CustomerCareColors.onPrimary,
                                elevation: 0,
                                textStyle: CustomerCareTextStyles.labelSm
                                    .copyWith(fontWeight: FontWeight.w700),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: onViewDetails,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: CustomerCareColors.onSurface,
                              side: const BorderSide(
                                color: CustomerCareColors.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              'Audit',
                              style: CustomerCareTextStyles.labelSm,
                            ),
                          ),
                        ],
                      )
                    else if (isSentToTeamLead)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Sent to Team Lead',
                          style: CustomerCareTextStyles.labelSm.copyWith(
                            color: CustomerCareColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else if (isDraft)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onCallVerify,
                              icon: const Icon(Icons.call, size: 16),
                              label: const Text('Call Customer / Open Draft'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    CustomerCareColors.warningContainer,
                                foregroundColor: CustomerCareColors.onSurface,
                                elevation: 0,
                                textStyle: CustomerCareTextStyles.labelSm
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: onViewDetails,
                            child: const Text('Details'),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onCallVerify,
                              icon: const Icon(Icons.phone_in_talk, size: 16),
                              label: Text(
                                caseItem.status == 'CUSTOMER_CARE_CONTACTED'
                                    ? 'Resume Verification'
                                    : 'Open Verification',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    CustomerCareColors.primaryContainer,
                                foregroundColor: CustomerCareColors.onPrimary,
                                elevation: 0,
                                textStyle: CustomerCareTextStyles.labelSm
                                    .copyWith(fontWeight: FontWeight.w700),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: onViewDetails,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: CustomerCareColors.onSurface,
                              side: const BorderSide(
                                color: CustomerCareColors.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              'Details',
                              style: CustomerCareTextStyles.labelSm,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Color accent, bool isVerified) {
    if (caseItem.isDraft) {
      return _statusPill(
        'DRAFT',
        CustomerCareColors.warningContainer,
        CustomerCareColors.onSurface,
      );
    }
    if (caseItem.isSubmitted && !isVerified) {
      return _statusPill(
        'PENDING VERIFICATION',
        CustomerCareColors.warningContainer,
        CustomerCareColors.onSurface,
      );
    }
    if (caseItem.isCodeRed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: CustomerCareColors.errorContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CustomerCareColors.error,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'CODE RED • CRITICAL',
              style: CustomerCareTextStyles.labelSm.copyWith(
                color: CustomerCareColors.onErrorContainer,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
          ],
        ),
      );
    }

    if (isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: CustomerCareColors.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'VERIFIED READY',
          style: CustomerCareTextStyles.labelSm.copyWith(
            color: CustomerCareColors.onSecondaryFixedVariant,
            fontWeight: FontWeight.w800,
            fontSize: 9,
          ),
        ),
      );
    }

    if (caseItem.pediatric) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: CustomerCareColors.tertiaryFixed,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'HIGH • PEDIATRIC',
          style: CustomerCareTextStyles.labelSm.copyWith(
            color: CustomerCareColors.onTertiaryFixed,
            fontWeight: FontWeight.w800,
            fontSize: 9,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CustomerCareColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        caseItem.statusLabel.toUpperCase(),
        style: CustomerCareTextStyles.labelSm.copyWith(
          color: CustomerCareColors.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _statusPill(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: CustomerCareTextStyles.labelSm.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
    );
  }

  String _formatTimestamp(String value) {
    final timestamp = DateTime.tryParse(value)?.toLocal();
    if (timestamp == null) return 'time unavailable';
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} $hour:$minute';
  }

  Widget _buildReqBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CustomerCareColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: CustomerCareTextStyles.labelSm.copyWith(
          color: CustomerCareColors.primary,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
