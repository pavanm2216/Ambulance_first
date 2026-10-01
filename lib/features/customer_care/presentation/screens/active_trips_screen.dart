import 'package:flutter/material.dart';

import '../../../../core/models/customer_care_case.dart';
import '../../../../core/services/customer_care_repository.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';
import '../widgets/live_gps_telemetry_dialog.dart';

class ActiveTripsScreen extends StatelessWidget {
  const ActiveTripsScreen({
    super.key,
    required this.onViewDetails,
    required this.onShowToast,
  });

  final ValueChanged<CustomerCareCase> onViewDetails;
  final ValueChanged<String> onShowToast;

  @override
  Widget build(BuildContext context) {
    final repo = CustomerCareRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final activeCases = repo.activeTripCases;
        final displayCases = activeCases;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Mission Monitoring Header
              Container(
                decoration: BoxDecoration(
                  color: CustomerCareColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.radar,
                                size: 20,
                                color: CustomerCareColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Active Ambulance Mission Monitoring',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CustomerCareTextStyles.headlineSm.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 90),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: CustomerCareColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${displayCases.length} En-Route',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CustomerCareTextStyles.labelSm.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Provide live, accurate operational updates to callers, patient families, and receiving emergency departments.',
                      style: CustomerCareTextStyles.bodySm.copyWith(
                        color: CustomerCareColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: CustomerCareColors.surfaceContainerLowest
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: CustomerCareColors.secondary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    displayCases.isEmpty
                                        ? 'GPS unavailable'
                                        : 'GPS data from backend',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CustomerCareTextStyles.labelSm.copyWith(
                                      color: CustomerCareColors.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'CAD Feed: Supabase',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: CustomerCareTextStyles.labelSm.copyWith(
                                color: CustomerCareColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Trip Cards List
              if (displayCases.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: Text('No active trips found.')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayCases.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final c = displayCases[index];
                    return _ActiveTripCard(
                      caseItem: c,
                      onOpenGps: () {
                        showDialog(
                          context: context,
                          builder: (_) => LiveGpsTelemetryDialog(caseItem: c),
                        );
                      },
                      onNotifyEta: () {
                        onShowToast(
                          'Notified ${c.receivingDoctor.isNotEmpty ? c.receivingDoctor : 'receiving team'}: Unit ETA ${c.etaMinutes != null ? '${c.etaMinutes}m' : 'unavailable'}.',
                        );
                      },
                      onUpdateFamily: () {
                        onShowToast(
                          'Family notification dispatch is not available from Customer Care yet.',
                        );
                      },
                      onCallPhone: () {
                        onShowToast(
                          'Calling family primary contact ${c.mobileNumber}...',
                        );
                      },
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({
    required this.caseItem,
    required this.onOpenGps,
    required this.onNotifyEta,
    required this.onUpdateFamily,
    required this.onCallPhone,
  });

  final CustomerCareCase caseItem;
  final VoidCallback onOpenGps;
  final VoidCallback onNotifyEta;
  final VoidCallback onUpdateFamily;
  final VoidCallback onCallPhone;

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${caseItem.id}',
                    style: CustomerCareTextStyles.telemetryDisplay.copyWith(
                      color: CustomerCareColors.primary,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    caseItem.dispatchTier.toUpperCase(),
                    style: CustomerCareTextStyles.labelSm.copyWith(
                      fontSize: 9.5,
                      color: CustomerCareColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CustomerCareColors.tertiaryContainer.withValues(
                    alpha: 0.2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: CustomerCareColors.tertiaryContainer,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'IN_TRANSIT • PATIENT ON-BOARD',
                      style: CustomerCareTextStyles.labelSm.copyWith(
                        color: CustomerCareColors.tertiaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Patient Scenario Strip
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CustomerCareColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 16,
                          color: CustomerCareColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${caseItem.patientName} (${caseItem.age} ${caseItem.gender.isNotEmpty ? caseItem.gender[0] : ""})',
                          style: CustomerCareTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: CustomerCareColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CustomerCareColors.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'STABILIZED',
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          color: CustomerCareColors.onErrorContainer,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Text(
                    caseItem.condition,
                    style: CustomerCareTextStyles.bodySm.copyWith(
                      color: CustomerCareColors.onSurfaceVariant,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Family Primary Contact
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CustomerCareColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CustomerCareColors.outlineVariant,
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Family Primary Contact',
                      style: CustomerCareTextStyles.labelSm.copyWith(
                        fontSize: 9.5,
                      ),
                    ),
                    Text(
                      '${caseItem.customerName} (${caseItem.relationship}) • ${caseItem.mobileNumber}',
                      style: CustomerCareTextStyles.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: CustomerCareColors.onSurface,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: onUpdateFamily,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CustomerCareColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sms,
                              size: 13,
                              color: CustomerCareColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text('SMS', style: CustomerCareTextStyles.labelSm),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onCallPhone,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CustomerCareColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.call,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Call',
                              style: CustomerCareTextStyles.labelSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Vehicle & Highway Live Telemetry Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CustomerCareColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.emergency,
                          size: 16,
                          color: CustomerCareColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          caseItem.ambulance?.isNotEmpty == true
                              ? caseItem.ambulance!
                              : 'Unit 04 (Mercedes Sprinter MICU)',
                          style: CustomerCareTextStyles.labelSm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: CustomerCareColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      caseItem.telemetrySignalFreshness,
                      style: CustomerCareTextStyles.labelSm.copyWith(
                        color: CustomerCareColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Dark Telemetry Canvas
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: CustomerCareColors.tacticalNavBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CustomerCareColors.tacticalNavBorder,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              caseItem.currentTelemetryLocation.isNotEmpty
                                  ? caseItem.currentTelemetryLocation
                                  : 'NW HWY 101 @ MM 42',
                              style: CustomerCareTextStyles.labelSm.copyWith(
                                color: CustomerCareColors.primaryFixed,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CustomerCareColors.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LIVE ${caseItem.liveSpeedKmh > 0 ? caseItem.liveSpeedKmh : 74} KM/H',
                              style: CustomerCareTextStyles.labelSm.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'REMAINING',
                                style: CustomerCareTextStyles.labelSm.copyWith(
                                  color: CustomerCareColors.outlineVariant,
                                  fontSize: 8.5,
                                ),
                              ),
                              Text(
                                caseItem.remainingKm > 0
                                    ? '${caseItem.remainingKm} km'
                                    : 'Unavailable',
                                style: CustomerCareTextStyles.telemetryDisplay
                                    .copyWith(
                                      color: CustomerCareColors.primaryFixed,
                                      fontSize: 13,
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'ESTIMATED ARRIVAL',
                                style: CustomerCareTextStyles.labelSm.copyWith(
                                  color: CustomerCareColors.outlineVariant,
                                  fontSize: 8.5,
                                ),
                              ),
                              Text(
                                caseItem.etaMinutes != null
                                    ? '${caseItem.etaMinutes}m'
                                    : 'Unavailable',
                                style: CustomerCareTextStyles.telemetryDisplay
                                    .copyWith(
                                      color: CustomerCareColors.secondaryFixed,
                                      fontSize: 13,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Staff Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PHYSICIAN & PARAMEDIC',
                          style: CustomerCareTextStyles.labelSm.copyWith(
                            fontSize: 8.5,
                            color: CustomerCareColors.outline,
                          ),
                        ),
                        Text(
                          caseItem.doctorName.isNotEmpty
                              ? '${caseItem.doctorName} • ${caseItem.emtName}'
                              : 'Dr. S. Rao • A. Gomez',
                          style: CustomerCareTextStyles.labelSm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: CustomerCareColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'DRIVER OPERATOR',
                          style: CustomerCareTextStyles.labelSm.copyWith(
                            fontSize: 8.5,
                            color: CustomerCareColors.outline,
                          ),
                        ),
                        Text(
                          caseItem.driverName?.isNotEmpty == true
                              ? caseItem.driverName!
                              : 'Michael Vance',
                          style: CustomerCareTextStyles.labelSm.copyWith(
                            fontWeight: FontWeight.w700,
                            color: CustomerCareColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Route Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CustomerCareColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: CustomerCareColors.outlineVariant,
                width: 0.6,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: CustomerCareColors.outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pickup: ${caseItem.pickupAddress} (Transfer Complete)',
                        style: CustomerCareTextStyles.bodySm.copyWith(
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 10,
                      width: 1.5,
                      color: CustomerCareColors.outlineVariant,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: CustomerCareColors.primaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Receiving: ${caseItem.destinationHospital.isNotEmpty ? caseItem.destinationHospital : caseItem.destinationAddress}',
                        style: CustomerCareTextStyles.bodySm.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: CustomerCareColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ED Receiving Lead Notification Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CustomerCareColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_hospital,
                      size: 16,
                      color: CustomerCareColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ED Receiving Lead',
                          style: CustomerCareTextStyles.labelSm.copyWith(
                            fontSize: 9.5,
                          ),
                        ),
                        Text(
                          '${caseItem.receivingDoctor} (${caseItem.receivingDepartment})',
                          style: CustomerCareTextStyles.bodySm.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: onNotifyEta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomerCareColors.surfaceContainerHigh,
                    foregroundColor: CustomerCareColors.primaryContainer,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    textStyle: CustomerCareTextStyles.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Notify ETA'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Actions Row: LIVE GPS & Update Family
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenGps,
                  icon: const Icon(Icons.map, size: 16),
                  label: const Text('LIVE GPS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomerCareColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: CustomerCareTextStyles.labelSm.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onUpdateFamily,
                  icon: const Icon(Icons.share_location, size: 16),
                  label: const Text('Update Family'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CustomerCareColors.primaryContainer,
                    side: const BorderSide(
                      color: CustomerCareColors.outlineVariant,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: CustomerCareTextStyles.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
