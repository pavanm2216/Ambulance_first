import 'package:flutter/material.dart';
import '../../../core/models/booking.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_metrics.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/aeromed_map_preview.dart';
import '../../../shared/widgets/aeromed_card.dart';
import '../../../shared/widgets/aeromed_page.dart' hide AeroMedEmptyState;
import '../../../shared/widgets/aeromed_ticket_card.dart';
import '../../../shared/widgets/aeromed_ui_states.dart';
import '../../../shared/widgets/motion.dart';

class NoActiveTripPage extends StatelessWidget {
  const NoActiveTripPage({super.key, this.onBook});

  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    return AeroMedPage(
      child: Center(
        child: AeroMedEmptyState(
          icon: Icons.near_me_disabled_outlined,
          title: 'No Active Ambulance Dispatch',
          message:
              'When your ambulance request is verified and assigned, live GPS telemetry, crew milestones, and patient vitals will stream here.',
          actionLabel: onBook != null ? 'Book an Ambulance' : null,
          onAction: onBook,
        ),
      ),
    );
  }
}

/// AeroMed Active Trip Tracker Screen
/// Faithfully recreated from Stitch Screen #84a6a2dd90184992ae80d27d28504965
class ActiveTripPage extends StatefulWidget {
  const ActiveTripPage({super.key, required this.booking});
  final Booking booking;

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _progress = Tween<double>(begin: 0.35, end: 0.58).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final awaitingAssignment = booking.status == 'CUSTOMER_ACCEPTED';
    final tripStatus = awaitingAssignment
      ? 'DISPATCH CONFIRMED'
      : booking.status == 'PATIENT_PICKED_UP' || booking.status == 'IN_TRANSIT'
        ? 'PATIENT ONBOARD'
        : booking.status == 'ARRIVED'
          ? 'ARRIVED AT DESTINATION'
          : 'ON THE WAY';

    return AeroMedPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Live GPS Tracking Viewport with Overlay
          FadeSlideIn(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.primary.withValues( alpha: 0.3)),
                  boxShadow: softShadow(),
                ),
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) => AeroMedMapPreview(
                        progress: _progress.value,
                        height: 300,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                    ),
                    // Traffic status (top right)
                    Positioned(
                      top: 14,
                      left: 14,
                      right: 14,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 260),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh.withValues( alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const PulseDot(size: 6, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Traffic: Moderate • Clear Corridor',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ),
                    // Floating Telemetry ETA Card (bottom of map)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh.withValues( alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.outlineVariant),
                          boxShadow: softShadow(),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!awaitingAssignment) const PulseDot(size: 5, color: AppColors.primary),
                                      if (!awaitingAssignment) const SizedBox(width: 6),
                                      Text(
                                        tripStatus,
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  awaitingAssignment ? 'Awaiting ambulance assignment' : 'Live Dispatch Active',
                                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Phone layouts are intentionally stacked. The old implementation
                                // placed an unconstrained ETA column beside a fixed 180px route column,
                                // which overflowed narrow screens and produced Flutter's yellow/black
                                // debug overflow marker.
                                final compact = constraints.maxWidth < 390;

                                Widget etaContent() => Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          awaitingAssignment ? 'DISPATCH' : '${booking.etaMinutes} MIN',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.displaySmall.copyWith(
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          awaitingAssignment
                                              ? 'Your quotation was accepted'
                                              : 'Estimated arrival at pickup point',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                        ),
                                      ],
                                    );

                                Widget routeContent() => Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${booking.distanceKm.toStringAsFixed(1)} km',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                          style: AppTextStyles.routeIndicator.copyWith(color: AppColors.primary),
                                        ),
                                        Text(
                                          awaitingAssignment
                                              ? 'Assignment will appear here'
                                              : 'Live GPS • ${booking.tripMilestone}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.secondary),
                                        ),
                                      ],
                                    );

                                if (compact) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      etaContent(),
                                      const SizedBox(height: 6),
                                      routeContent(),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 5, child: etaContent()),
                                    const SizedBox(width: 12),
                                    Expanded(flex: 4, child: routeContent()),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Rapid Hospital Red Alert Hotline
          FadeSlideIn(
            delay: const Duration(milliseconds: 50),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues( alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.urgentRed.withValues( alpha: 0.4)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 360;
                  final copy = Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hospital Alert Active', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: AppColors.onErrorContainer)),
                        Text('Emergency room trauma team notified', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onErrorContainer)),
                      ],
                    ),
                  );
                  final button = ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.errorContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _showAlertDialog(context),
                    child: Text('Alert ER', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800)),
                  );
                  final icon = Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.urgentRed,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.urgentRed.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 22),
                  );
                  return compact
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [icon, const SizedBox(width: 12), copy]), const SizedBox(height: 12), Align(alignment: Alignment.centerRight, child: button)])
                      : Row(children: [icon, const SizedBox(width: 12), copy, button]);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Tactical Boarding Pass Card (Lead Paramedic & Crew)
          FadeSlideIn(
            delay: const Duration(milliseconds: 90),
            child: AeroMedTicketCard(
              notchColor: AppColors.surface,
              topChild: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2EEEE),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                'UNIT ${widget.booking.vehicleNumber}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.onTactileCard,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues( alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                widget.booking.transportModeLabel,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: const Color(0xFF06766D),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF06766D)),
                            const SizedBox(width: 4),
                            Text(
                              'Critical Care Ready',
                              style: AppTextStyles.caption.copyWith(color: const Color(0xFF06766D), fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0A8F83),
                              ),
                              child: const Center(
                                child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.onTactileCard,
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('4.9', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
                                    const SizedBox(width: 2),
                                    const Icon(Icons.star_rounded, size: 10, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ramesh Gowda',
                                style: AppTextStyles.headlineSmall.copyWith(
                                  color: AppColors.onTactileCard,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Lead Mobile Paramedic Pilot • 11 yrs exp',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.onTactileCardSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Nurse spec
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F7F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medical_services_rounded, size: 18, color: Color(0xFF06766D)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nurse Ananya', style: AppTextStyles.labelMedium.copyWith(color: AppColors.onTactileCard, fontWeight: FontWeight.w700)),
                                Text('Critical Care Specialist Onboard', style: AppTextStyles.caption.copyWith(color: AppColors.onTactileCardSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD8EFEC),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              'O₂ FULL ALS',
                              style: AppTextStyles.labelSmall.copyWith(color: const Color(0xFF064B45), fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomChild: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.onTactileCard,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: Text('Call Crew', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
                        onPressed: () => _showCrewDialog(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD2E0DE)),
                          foregroundColor: AppColors.onTactileCard,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: Text('Chat', style: AppTextStyles.labelMedium.copyWith(color: AppColors.onTactileCard, fontWeight: FontWeight.w700)),
                        onPressed: () => _showChatDialog(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F7F7),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD2E0DE)),
                      ),
                      child: const Icon(Icons.share_rounded, size: 18, color: AppColors.onTactileCard),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (widget.booking.vitals.isNotEmpty) ...[
            FadeSlideIn(
              delay: const Duration(milliseconds: 115),
              child: AeroMedCard(
                shadow: false,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 5,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monitor_heart_outlined, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Live Patient Vitals', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Text('LIVE', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _VitalChip('HR', '${widget.booking.vitals.last.heartRate} bpm'),
                    _VitalChip('SpO₂', '${widget.booking.vitals.last.spo2}%'),
                    _VitalChip('BP', widget.booking.vitals.last.bp),
                    _VitalChip('RR', '${widget.booking.vitals.last.respiratoryRate}/min'),
                    _VitalChip('Temp', '${widget.booking.vitals.last.temperature.toStringAsFixed(1)}°C'),
                  ]),
                  const SizedBox(height: 6),
                  Text('Last recorded ${widget.booking.vitals.last.time} • Shared with receiving team', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Live Step Journey Tracker (Dark Forest Ground Deck)
          FadeSlideIn(
            delay: const Duration(milliseconds: 130),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.outlineVariant),
                boxShadow: softShadow(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Transit Milestones',
                              style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Text(
                          'STEP 3 OF 6',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // 6 Milestone nodes with vertical spine
                  _MilestoneRow(
                    title: 'Booking Confirmed',
                    subtitle: 'Priority medical dispatch allocated',
                    time: '2:18 PM',
                    isCompleted: true,
                  ),
                  _MilestoneRow(
                    title: 'Ambulance Assigned',
                    subtitle: 'ALS Rig KA 01 AB 1234 En Route',
                    time: '2:20 PM',
                    isCompleted: true,
                  ),
                  _MilestoneRow(
                    title: 'On the Way to Pickup',
                    subtitle: 'Intermediate ring road corridor',
                    time: 'ETA 12m',
                    isActive: true,
                  ),
                  _MilestoneRow(
                    title: 'Arrived at Pickup Location',
                    subtitle: 'Patient handover protocol',
                    time: 'Pending',
                    isPending: true,
                  ),
                  _MilestoneRow(
                    title: 'Patient Onboard & Stable',
                    subtitle: 'Vitals streaming to ER triage',
                    time: 'Pending',
                    isPending: true,
                  ),
                  _MilestoneRow(
                    title: 'Arrived at ${widget.booking.destinationHospital.isEmpty ? widget.booking.destination : widget.booking.destinationHospital}',
                    subtitle: 'Trauma bay direct handover',
                    time: 'Pending',
                    isPending: true,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  void _showCrewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crew contact'),
        content: Text('Driver: ${widget.booking.driverName}\nPhone: ${widget.booking.driverPhone}\nEMT: ${widget.booking.emtName}\nUnit: ${widget.booking.vehicleNumber}'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crew chat'),
        content: const Text('Secure crew messaging is ready for backend integration. For this demo, contact the crew by phone.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hospital alert'),
        content: const Text('Emergency room alert request recorded for this trip.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

}

class _VitalChip extends StatelessWidget {
  const _VitalChip(this.label, this.value);
  final String label; final String value;
  @override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),decoration:BoxDecoration(color:AppColors.surfaceContainerHigh,borderRadius:BorderRadius.circular(12)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:AppTextStyles.caption),Text(value,style:AppTextStyles.bodyStrong)]));
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.title,
    required this.subtitle,
    required this.time,
    this.isCompleted = false,
    this.isActive = false,
    this.isPending = false,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final String time;
  final bool isCompleted;
  final bool isActive;
  final bool isPending;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Left spine with marker
          Column(
            children: [
              if (isCompleted)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 14, color: AppColors.onPrimary),
                )
              else if (isActive)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: mintGlow(opacity: 0.8),
                  ),
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerHighest,
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 42,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isCompleted ? AppColors.primary : AppColors.surfaceContainerHighest,
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 270;
                  final text = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isActive
                              ? AppColors.primary
                              : (isCompleted ? AppColors.textPrimary : AppColors.textMuted),
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                  final timeBadge = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      time,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isActive ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  );
                  return compact
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [text, const SizedBox(height: 5), timeBadge])
                      : Row(children: [Expanded(child: text), const SizedBox(width: 6), timeBadge]);
                },
              ),
            ),
          ),
      ],
    );
  }

}
