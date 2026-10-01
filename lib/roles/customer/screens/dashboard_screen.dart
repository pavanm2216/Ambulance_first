
import 'package:flutter/material.dart';

import '../../../core/models/booking.dart';
import '../../../core/services/driver_location_store.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_metrics.dart';
import '../../../shared/theme/app_text_styles.dart';
import '../../../shared/widgets/aeromed_button.dart';
import '../../../shared/widgets/aeromed_card.dart';
import '../../../shared/widgets/aeromed_map_preview.dart';
import '../../../shared/widgets/aeromed_page.dart';
import '../../../shared/widgets/motion.dart';


// ============================================================
// CUSTOMER DASHBOARD
// ============================================================

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({
    super.key,
    required this.bookings,
    required this.onBook,
    required this.onTrack,
    required this.onBookings,
    this.onQuotations,
    this.onNotifications,
    this.onCustomerCare,
  });

  final List<Booking> bookings;

  final VoidCallback onBook;
  final VoidCallback onTrack;
  final VoidCallback onBookings;

  final VoidCallback? onQuotations;
  final VoidCallback? onNotifications;
  final VoidCallback? onCustomerCare;


  @override
  Widget build(BuildContext context) {
    final active =
        bookings.where((b) => b.isActive).toList();

    final activeBooking =
        active.isNotEmpty
            ? active.first
            : null;

    return AeroMedPage(
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final width =
              constraints.maxWidth;

          final isMobile =
              width <= 480;

          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [

              // =================================================
              // GREETING
              // =================================================

              FadeSlideIn(
                child: _GreetingBar(
                  isMobile:
                      isMobile,
                  onNotifications:
                      onNotifications ??
                          onBookings,
                  onEmergency:
                      onBook,
                ),
              ),

              SizedBox(
                height:
                    isMobile ? 14 : 20,
              ),


              // =================================================
              // BOOK AMBULANCE — FIRST CARD
              // =================================================
              // The primary customer action is intentionally placed
              // immediately below the greeting. Tapping the CTA uses
              // the existing onBook callback and opens the full
              // Book Ambulance flow.

              FadeSlideIn(
                delay:
                    const Duration(
                  milliseconds: 50,
                ),
                child:
                    _WhereDoYouNeedCard(
                  onBook:
                      onBook,
                  isMobile:
                      isMobile,
                ),
              ),


              SizedBox(
                height: isMobile ? 10 : 14,
              ),

              FadeSlideIn(
                delay: const Duration(milliseconds: 70),
                child: _CustomerCareBookingCard(
                  onTap: onCustomerCare,
                  isMobile: isMobile,
                ),
              ),


              // =================================================
              // ACTIVE TRIP
              // =================================================

              if (activeBooking != null) ...[
                SizedBox(
                  height:
                      isMobile ? 12 : 20,
                ),

                FadeSlideIn(
                  delay:
                      const Duration(
                    milliseconds: 90,
                  ),
                  child:
                      _ActiveTripHeroCard(
                    booking:
                        activeBooking,
                    onTrack:
                        onTrack,
                    isMobile:
                        isMobile,
                  ),
                ),
              ],


              // =================================================
              // QUOTATION
              // =================================================

              if (bookings.any(
                (b) =>
                    b.hasPendingQuotation,
              )) ...[
                const SizedBox(
                  height: 8,
                ),

                _QuotationNotification(
                  onReview:
                      onQuotations ??
                          onBookings,
                  isMobile:
                      isMobile,
                ),
              ],


              // =================================================
              // EMERGENCY
              // =================================================

              SizedBox(
                height:
                    isMobile ? 12 : 20,
              ),

              FadeSlideIn(
                delay:
                    const Duration(
                  milliseconds: 130,
                ),
                child:
                    _EmergencyBanner(
                  onEmergency:
                      onBook,
                  isMobile:
                      isMobile,
                ),
              ),


              // =================================================
              // QUICK SERVICES
              // =================================================

              SizedBox(
                height:
                    isMobile ? 18 : 24,
              ),

              FadeSlideIn(
                delay:
                    const Duration(
                  milliseconds: 170,
                ),
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [

                    Padding(
                      padding:
                          const EdgeInsets
                              .only(
                        left: 4,
                      ),
                      child:
                          Text(
                        'Quick Services',
                        style:
                            AppTextStyles
                                .headlineSmall
                                .copyWith(
                          fontWeight:
                              FontWeight
                                  .w700,
                          fontSize:
                              isMobile
                                  ? 17
                                  : null,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _QuickServicesGrid(
                      onBook:
                          onBook,
                      onTrack:
                          onTrack,
                      onBookings:
                          onBookings,
                      onQuotations:
                          onQuotations ??
                              onBookings,
                      isMobile:
                          isMobile,
                    ),
                  ],
                ),
              ),


              // =================================================
              // PARAMEDIC
              // =================================================

              SizedBox(
                height:
                    isMobile ? 14 : 20,
              ),

              FadeSlideIn(
                delay:
                    const Duration(
                  milliseconds: 210,
                ),
                child:
                    _LeadParamedicCard(
                  isMobile:
                      isMobile,
                ),
              ),

              const SizedBox(
                height: 12,
              ),
            ],
          );
        },
      ),
    );
  }
}


// ============================================================
// GREETING BAR
// ============================================================

class _GreetingBar
    extends StatelessWidget {
  const _GreetingBar({
    required this.isMobile,
    required this.onNotifications,
    required this.onEmergency,
  });

  final bool isMobile;

  final VoidCallback
      onNotifications;

  final VoidCallback
      onEmergency;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Row(
                children: [

                  Text(
                    'Good afternoon,',
                    style:
                        AppTextStyles
                            .bodySmall
                            .copyWith(
                      fontSize:
                          isMobile
                              ? 9
                              : null,
                      color:
                          AppColors
                              .textSecondary,
                    ),
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Container(
                    width: 5,
                    height: 5,
                    decoration:
                        const BoxDecoration(
                      color:
                          AppColors
                              .primary,
                      shape:
                          BoxShape.circle,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                'Kushal Kumar',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    AppTextStyles
                        .headlineMedium
                        .copyWith(
                  fontWeight:
                      FontWeight.w700,
                  fontSize:
                      isMobile
                          ? 19
                          : null,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [

            _CircleHeaderButton(
              icon:
                  Icons.notifications_outlined,
              hasBadge:
                  true,
              onTap:
                  onNotifications,
              size:
                  isMobile ? 38 : 44,
            ),

            const SizedBox(
              width: 6,
            ),

            _CircleHeaderButton(
              icon:
                  Icons.emergency_rounded,
              color:
                  AppColors.urgentRed,
              onTap:
                  onEmergency,
              size:
                  isMobile ? 38 : 44,
            ),
          ],
        ),
      ],
    );
  }
}


// ============================================================
// HEADER BUTTON
// ============================================================

class _CircleHeaderButton
    extends StatelessWidget {
  const _CircleHeaderButton({
    required this.icon,
    required this.onTap,
    this.color =
        AppColors.textPrimary,
    this.hasBadge = false,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool hasBadge;
  final double size;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Stack(
      children: [

        Material(
          color:
              AppColors
                  .surfaceContainerHigh,
          shape:
              const CircleBorder(),

          child: InkWell(
            customBorder:
                const CircleBorder(),
            onTap:
                onTap,

            child: SizedBox(
              width:
                  size,
              height:
                  size,

              child:
                  Icon(
                icon,
                color:
                    color,
                size:
                    size * 0.48,
              ),
            ),
          ),
        ),

        if (hasBadge)
          Positioned(
            top:
                size * 0.16,
            right:
                size * 0.16,

            child:
                Container(
              width:
                  7,
              height:
                  7,

              decoration:
                  BoxDecoration(
                color:
                    AppColors
                        .primary,
                shape:
                    BoxShape
                        .circle,

                border:
                    Border.all(
                  color:
                      AppColors
                          .surface,
                  width:
                      1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}


// ============================================================
// ACTIVE TRIP HERO
// ============================================================

class _ActiveTripHeroCard
    extends StatelessWidget {
  const _ActiveTripHeroCard({
    required this.booking,
    required this.onTrack,
    required this.isMobile,
  });

  final Booking booking;
  final VoidCallback onTrack;
  final bool isMobile;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration:
          BoxDecoration(
        color:
            AppColors
                .surfaceContainerLowest,

        borderRadius:
            BorderRadius.circular(
          AppRadius.card,
        ),

        border:
            Border.all(
          color:
              AppColors.primary
                  .withValues( alpha: 0.25
          ),
        ),

        boxShadow:
            softShadow(
          opacity:
              0.7,
        ),
      ),

      child:
          Stack(
        children: [

          Positioned(
            right:
                -35,
            top:
                -35,

            child:
                Container(
              width:
                  130,
              height:
                  130,

              decoration:
                  BoxDecoration(
                shape:
                    BoxShape
                        .circle,

                color:
                    AppColors
                        .primary
                        .withValues( alpha: 0.12
                ),

                boxShadow:
                    mintGlow(
                  opacity:
                      0.3,
                ),
              ),
            ),
          ),

          Padding(
            padding:
                EdgeInsets.all(
              isMobile
                  ? 14
                  : 22,
            ),

            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                // ------------------------------------------
                // MOBILE: STACKED HEADER
                // ------------------------------------------

                if (isMobile)
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                    children: [

                      Row(
                        children: [

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  8,
                              vertical:
                                  5,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors
                                      .surfaceContainer,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                AppRadius
                                    .pill,
                              ),
                            ),

                            child:
                                Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [

                                const PulseDot(
                                  size:
                                      5,
                                  color:
                                      AppColors
                                          .primary,
                                ),

                                const SizedBox(
                                  width:
                                      5,
                                ),

                                Text(
                                  'AMBULANCE ON THE WAY',
                                  style:
                                      AppTextStyles
                                          .labelSmall
                                          .copyWith(
                                    color:
                                        AppColors
                                            .primary,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                    fontSize:
                                        6.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  9,
                              vertical:
                                  5,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors
                                      .surfaceContainer,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),

                            child:
                                Row(
                              children: [

                                Text(
                                  'ETA ',
                                  style:
                                      AppTextStyles
                                          .labelSmall
                                          .copyWith(
                                    color:
                                        AppColors
                                            .primary,
                                    fontSize:
                                        7,
                                  ),
                                ),

                                Text(
                                  '${booking.etaMinutes}',
                                  style:
                                      AppTextStyles
                                          .bodyStrong
                                          .copyWith(
                                    fontSize:
                                        13,
                                  ),
                                ),

                                const SizedBox(
                                  width:
                                      2,
                                ),

                                Text(
                                  'min',
                                  style:
                                      AppTextStyles
                                          .labelSmall
                                          .copyWith(
                                    color:
                                        AppColors
                                            .primary,
                                    fontSize:
                                        7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height:
                            7,
                      ),

                      Text(
                        booking.id,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            AppTextStyles
                                .bodyStrong
                                .copyWith(
                          fontSize:
                              10,
                        ),
                      ),

                      const SizedBox(
                        height:
                            2,
                      ),

                      Text(
                        booking
                            .ambulanceType,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            AppTextStyles
                                .supporting
                                .copyWith(
                          fontSize:
                              7.5,
                        ),
                      ),
                    ],
                  )

                // ------------------------------------------
                // DESKTOP / TABLET HEADER
                // ------------------------------------------

                else
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Expanded(
                        child:
                            _ActiveTripHeader(
                          booking:
                              booking,
                        ),
                      ),

                      const SizedBox(
                        width:
                            10,
                      ),

                      _EtaBox(
                        booking:
                            booking,
                      ),
                    ],
                  ),


                SizedBox(
                  height:
                      isMobile
                          ? 10
                          : 18,
                ),


                // ------------------------------------------
                // MAP
                // ------------------------------------------

                _LiveAmbulanceMap(
                  booking:
                      booking,
                  isMobile:
                      isMobile,
                ),


                SizedBox(
                  height:
                      isMobile
                          ? 10
                          : 18,
                ),


                // ------------------------------------------
                // ROUTE
                // ------------------------------------------

                _RouteCard(
                  booking:
                      booking,
                  isMobile:
                      isMobile,
                ),


                SizedBox(
                  height:
                      isMobile
                          ? 10
                          : 18,
                ),


                // ------------------------------------------
                // TIMELINE
                // ------------------------------------------

                _CompactTimeline(
                  isMobile:
                      isMobile,
                ),


                SizedBox(
                  height:
                      isMobile
                          ? 10
                          : 20,
                ),


                // ------------------------------------------
                // TRACK BUTTON
                // ------------------------------------------

                SizedBox(
                  width:
                      double.infinity,

                  child:
                      AeroMedButton(
                    label:
                        'Track Live Trip',

                    icon:
                        Icons
                            .near_me_rounded,

                    height:
                        isMobile
                            ? 43
                            : 48,

                    onTap:
                        onTrack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// ACTIVE HEADER
// ============================================================

class _ActiveTripHeader
    extends StatelessWidget {
  const _ActiveTripHeader({
    required this.booking,
  });

  final Booking booking;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                12,
            vertical:
                6,
          ),

          decoration:
              BoxDecoration(
            color:
                AppColors
                    .surfaceContainer,

            borderRadius:
                BorderRadius.circular(
              AppRadius.pill,
            ),
          ),

          child:
              Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [

              const PulseDot(
                size:
                    6,
                color:
                    AppColors.primary,
              ),

              const SizedBox(
                width:
                    7,
              ),

              Text(
                'AMBULANCE ON THE WAY',
                style:
                    AppTextStyles
                        .labelSmall
                        .copyWith(
                  color:
                      AppColors.primary,
                  fontWeight:
                      FontWeight.w800,
                  letterSpacing:
                      0.6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height:
              6,
        ),

        Text(
          booking.id,
          maxLines:
              1,
          overflow:
              TextOverflow
                  .ellipsis,
          style:
              AppTextStyles
                  .telemetryMetric
                  .copyWith(
            color:
                AppColors.textPrimary,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        Text(
          booking.ambulanceType,
          maxLines:
              1,
          overflow:
              TextOverflow
                  .ellipsis,
          style:
              AppTextStyles
                  .bodySmall,
        ),
      ],
    );
  }
}


// ============================================================
// ETA BOX
// ============================================================

class _EtaBox extends StatelessWidget {
  const _EtaBox({
    required this.booking,
  });

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 76,
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'ETA',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              fontSize: 9,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${booking.etaMinutes}',
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 34,
                  height: 0.95,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                'min',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '3.4 km away',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
              height: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// LIVE MAP
// ============================================================

class _LiveAmbulanceMap extends StatelessWidget {
  const _LiveAmbulanceMap({
    required this.booking,
    required this.isMobile,
  });

  final Booking booking;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DriverLocationStore.instance,
      builder: (context, _) {
        final live = DriverLocationStore.instance.forBooking(booking.id);
        final sharing = live != null;
        final updated = live?.updatedAt;
        final updatedLabel = updated == null
            ? 'Waiting for driver GPS'
            : 'Updated ${_relativeTime(updated)}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PulseDot(
                  size: 7,
                  color: sharing ? AppColors.success : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sharing ? 'LIVE AMBULANCE LOCATION' : 'AMBULANCE LOCATION',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: sharing ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontSize: isMobile ? 6.5 : null,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  updatedLabel,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: isMobile ? 7 : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(isMobile ? 15 : 18),
                  child: AeroMedMapPreview(
                    progress: sharing ? 0.62 : 0.55,
                    height: isMobile ? 135 : 170,
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _LiveAmbulanceMarkerPainter(live: live),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isMobile ? 190 : 260),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (sharing ? AppColors.success : AppColors.primary)
                            .withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sharing ? Icons.local_shipping_rounded : Icons.location_searching_rounded,
                          size: 15,
                          color: sharing ? AppColors.success : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            sharing
                                ? '${live.ambulanceUnit} • Driver location live'
                                : '${booking.vehicleNumber.isEmpty ? 'Assigned ambulance' : booking.vehicleNumber} • Waiting for GPS',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: isMobile ? 7 : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            if (sharing)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${live.latitude.toStringAsFixed(6)}, ${live.longitude.toStringAsFixed(6)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: isMobile ? 7 : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${live.speedKmh.toStringAsFixed(0)} km/h',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: isMobile ? 7 : null,
                    ),
                  ),
                ],
              )
            else
              Text(
                '${booking.vehicleNumber.isEmpty ? 'Assigned ambulance' : booking.vehicleNumber} is assigned. Live driver GPS will appear here once the driver location is connected.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.supporting.copyWith(
                  fontSize: isMobile ? 7 : null,
                ),
              ),
          ],
        );
      },
    );
  }

  String _relativeTime(DateTime time) {
    final seconds = DateTime.now().difference(time).inSeconds;
    if (seconds <= 2) return 'just now';
    if (seconds < 60) return '${seconds}s ago';
    return '${(seconds / 60).floor()}m ago';
  }
}

class _LiveAmbulanceMarkerPainter extends CustomPainter {
  const _LiveAmbulanceMarkerPainter({required this.live});

  final DriverLocationSnapshot? live;

  @override
  void paint(Canvas canvas, Size size) {
    if (live == null) return;

    // This is a stylized vehicle marker over the existing prototype route.
    // The real geographic position will be used by the map SDK/backend phase.
    final x = size.width * 0.62;
    final y = size.height * 0.48;
    final glow = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 19, glow);

    final marker = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 11, marker);

    final iconPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x - 5, y + 3), Offset(x + 5, y + 3), iconPaint);
    canvas.drawLine(Offset(x - 4, y - 2), Offset(x + 4, y - 2), iconPaint);
    canvas.drawCircle(Offset(x - 4, y + 5), 1.5, iconPaint);
    canvas.drawCircle(Offset(x + 4, y + 5), 1.5, iconPaint);
  }

  @override
  bool shouldRepaint(covariant _LiveAmbulanceMarkerPainter oldDelegate) => oldDelegate.live != live;
}

// ============================================================
// ROUTE CARD
// ============================================================

class _RouteCard
    extends StatelessWidget {
  const _RouteCard({
    required this.booking,
    required this.isMobile,
  });

  final Booking booking;
  final bool isMobile;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          EdgeInsets.all(
        isMobile
            ? 10
            : 16,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors
                .surfaceContainer
                .withValues(
              alpha: 0.70
        ),

        borderRadius:
            BorderRadius.circular(
          isMobile
              ? 14
              : 18,
        ),
      ),

      child:
          Column(
        children: [

          _RouteLocation(
            color:
                AppColors.primary,

            title:
                'PICKUP LOCATION',

            value:
                booking.pickup,

            isMobile:
                isMobile,
          ),

          Padding(
            padding:
                EdgeInsets.only(
              left:
                  isMobile
                      ? 4
                      : 4.5,
              top:
                  3,
              bottom:
                  3,
            ),

            child:
                Align(
              alignment:
                  Alignment
                      .centerLeft,

              child:
                  Container(
                width:
                    1.5,
                height:
                    isMobile
                        ? 11
                        : 16,
                color:
                    AppColors
                        .outlineVariant,
              ),
            ),
          ),

          _RouteLocation(
            color:
                AppColors.secondary,

            title:
                'HOSPITAL DESTINATION',

            value:
                booking.destination,

            isMobile:
                isMobile,
          ),
        ],
      ),
    );
  }
}


// ============================================================
// ROUTE LOCATION
// ============================================================

class _RouteLocation
    extends StatelessWidget {
  const _RouteLocation({
    required this.color,
    required this.title,
    required this.value,
    required this.isMobile,
  });

  final Color color;
  final String title;
  final String value;
  final bool isMobile;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [

        Container(
          width:
              isMobile
                  ? 9
                  : 10,
          height:
              isMobile
                  ? 9
                  : 10,

          decoration:
              BoxDecoration(
            color:
                color,
            shape:
                BoxShape.circle,

            boxShadow:
                color ==
                        AppColors
                            .primary
                    ? mintGlow(
                        opacity:
                            0.55,
                      )
                    : null,
          ),
        ),

        SizedBox(
          width:
              isMobile
                  ? 8
                  : 12,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [

              Text(
                title,
                style:
                    AppTextStyles
                        .labelSmall
                        .copyWith(
                  fontSize:
                      isMobile
                          ? 6.5
                          : null,
                ),
              ),

              const SizedBox(
                height:
                    1,
              ),

              Text(
                value,
                maxLines:
                    1,
                overflow:
                    TextOverflow
                        .ellipsis,
                style:
                    AppTextStyles
                        .bodyLarge
                        .copyWith(
                  fontWeight:
                      FontWeight.w700,
                  fontSize:
                      isMobile
                          ? 9
                          : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// ============================================================
// COMPACT TIMELINE
// ============================================================

class _CompactTimeline
    extends StatelessWidget {
  const _CompactTimeline({
    required this.isMobile,
  });

  final bool isMobile;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,

      children: const [

        _TimelineStep(
          label:
              'Booked',
          state:
              _StepState.completed,
        ),

        _TimelineStep(
          label:
              'Assigned',
          state:
              _StepState.completed,
        ),

        _TimelineStep(
          label:
              'En Route',
          state:
              _StepState.active,
        ),

        _TimelineStep(
          label:
              'Arriving',
          state:
              _StepState.upcoming,
        ),
      ],
    );
  }
}


// ============================================================
// TIMELINE
// ============================================================

enum _StepState {
  completed,
  active,
  upcoming,
}


class _TimelineStep
    extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.state,
  });

  final String label;
  final _StepState state;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [

        if (state ==
            _StepState.completed)

          Container(
            width:
                18,
            height:
                18,

            decoration:
                const BoxDecoration(
              color:
                  AppColors.primary,
              shape:
                  BoxShape.circle,
            ),

            child:
                const Icon(
              Icons.check_rounded,
              size:
                  12,
              color:
                  AppColors.onPrimary,
            ),
          )

        else if (state ==
            _StepState.active)

          Container(
            width:
                20,
            height:
                20,

            decoration:
                BoxDecoration(
              color:
                  AppColors.primary,
              shape:
                  BoxShape.circle,

              boxShadow:
                  mintGlow(
                opacity:
                    0.9,
              ),
            ),

            child:
                Center(
              child:
                  Container(
                width:
                    8,
                height:
                    8,

                decoration:
                    const BoxDecoration(
                  color:
                      AppColors
                          .onPrimaryContainer,
                  shape:
                      BoxShape.circle,
                ),
              ),
            ),
          )

        else

          Container(
            width:
                16,
            height:
                16,

            decoration:
                const BoxDecoration(
              color:
                  AppColors
                      .surfaceContainerHighest,
              shape:
                  BoxShape.circle,
            ),
          ),

        const SizedBox(
          height:
              5,
        ),

        Text(
          label,
          style:
              AppTextStyles
                  .labelSmall
                  .copyWith(
            fontSize:
                7,
            color:
                state ==
                        _StepState.active
                    ? AppColors
                        .primary
                    : state ==
                            _StepState
                                .completed
                        ? AppColors
                            .textPrimary
                        : AppColors
                            .textMuted,
            fontWeight:
                state ==
                        _StepState.active
                    ? FontWeight.w800
                    : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}


// ============================================================
// QUOTATION NOTIFICATION
// ============================================================

class _QuotationNotification
    extends StatelessWidget {
  const _QuotationNotification({
    required this.onReview,
    required this.isMobile,
  });

  final VoidCallback onReview;
  final bool isMobile;


  @override
  Widget build(
    BuildContext context,
  ) {
    return AeroMedCard(
      shadow:
          false,

      padding:
          EdgeInsets.all(
        isMobile
            ? 10
            : 14,
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .center,

        children: [

          Container(
            width:
                isMobile
                    ? 30
                    : 38,
            height:
                isMobile
                    ? 30
                    : 38,

            decoration:
                BoxDecoration(
              color:
                  AppColors
                      .primary
                      .withValues(
                    alpha: 0.08
              ),

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child:
                Icon(
              Icons
                  .receipt_long_rounded,
              color:
                  AppColors.primary,
              size:
                  isMobile
                      ? 15
                      : 20,
            ),
          ),

          const SizedBox(
            width:
                8,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                Text(
                  'Quotation ready for confirmation',
                  maxLines:
                      1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      AppTextStyles
                          .bodyStrong
                          .copyWith(
                    fontSize:
                        isMobile
                            ? 8
                            : null,
                  ),
                ),

                Text(
                  'Review and accept your latest ambulance quotation.',
                  maxLines:
                      2,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      AppTextStyles
                          .supporting
                          .copyWith(
                    fontSize:
                        isMobile
                            ? 6.8
                            : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width:
                5,
          ),

          TextButton(
            onPressed:
                onReview,

            style:
                TextButton.styleFrom(
              minimumSize:
                  Size.zero,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal:
                    7,
                vertical:
                    5,
              ),
            ),

            child:
                Text(
              'Review',
              style:
                  AppTextStyles
                      .labelMedium
                      .copyWith(
                color:
                    AppColors.primary,
                fontSize:
                    isMobile
                        ? 8
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// CUSTOMER CARE BOOKING
// ============================================================

class _CustomerCareBookingCard extends StatelessWidget {
  const _CustomerCareBookingCard({
    required this.onTap,
    required this.isMobile,
  });

  final VoidCallback? onTap;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: softShadow(),
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 42 : 48,
            height: isMobile ? 42 : 48,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: AppColors.primaryDark,
              size: isMobile ? 21 : 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book through Customer Care',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontSize: isMobile ? 12 : 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Need help? Our Customer Care team can book an ambulance for you.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: isMobile ? 8.5 : null,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: isMobile ? 92 : 132,
            child: AeroMedButton(
              label: isMobile ? 'Call Care' : 'Call Customer Care',
              icon: Icons.phone_in_talk_rounded,
              expand: true,
              height: isMobile ? 40 : 44,
              onTap: onTap ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================
// WHERE DO YOU NEED AN AMBULANCE
// ============================================================

class _WhereDoYouNeedCard
    extends StatefulWidget {
  const _WhereDoYouNeedCard({
    required this.onBook,
    required this.isMobile,
  });

  final VoidCallback onBook;
  final bool isMobile;


  @override
  State<_WhereDoYouNeedCard>
      createState() =>
          _WhereDoYouNeedCardState();
}


class _WhereDoYouNeedCardState
    extends State<
        _WhereDoYouNeedCard> {

  int _selectedChip =
      0;

  final List<String>
      _chips = [
    'Now',
    'Today',
    'Tomorrow',
    'Scheduled',
  ];


  @override
  Widget build(
    BuildContext context,
  ) {
    final mobile =
        widget.isMobile;

    return Container(

      width:
          double.infinity,

      padding:
          EdgeInsets.all(
        mobile
            ? 14
            : 22,
      ),

      decoration:
          BoxDecoration(

        color:
            AppColors
                .surfaceBright,

        borderRadius:
            BorderRadius.circular(
          AppRadius.card,
        ),

        border:
            Border.all(
          color:
              AppColors
                  .outlineVariant,
        ),

        boxShadow:
            softShadow(),
      ),

      child:
          Column(

        crossAxisAlignment:
            CrossAxisAlignment
                .stretch,

        children: [

          // ==================================================
          // TITLE
          // ==================================================

          Row(

            crossAxisAlignment:
                CrossAxisAlignment
                    .center,

            children: [

              Expanded(

                child:
                    Text(

                  'Where do you need an ambulance?',

                  maxLines:
                      mobile
                          ? 2
                          : 1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      AppTextStyles
                          .headlineSmall
                          .copyWith(

                    fontWeight:
                        FontWeight.w700,

                    fontSize:
                        mobile
                            ? 12
                            : 16,
                  ),
                ),
              ),

              const SizedBox(
                width:
                    6,
              ),

              Container(

                width:
                    mobile
                        ? 30
                        : 36,

                height:
                    mobile
                        ? 30
                        : 36,

                decoration:
                    BoxDecoration(

                  color:
                      AppColors
                          .surfaceContainer,

                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                child:
                    Icon(

                  Icons
                      .medical_services_rounded,

                  color:
                      AppColors.primary,

                  size:
                      mobile
                          ? 16
                          : 20,
                ),
              ),
            ],
          ),


          SizedBox(
            height:
                mobile
                    ? 10
                    : 18,
          ),


          // ==================================================
          // ROUTE CONTAINER
          // ==================================================

          Container(

            width:
                double.infinity,

            padding:
                EdgeInsets.all(
              mobile
                  ? 10
                  : 16,
            ),

            decoration:
                BoxDecoration(

              color:
                  AppColors
                      .surfaceContainerLowest,

              borderRadius:
                  BorderRadius.circular(
                mobile
                    ? 14
                    : 18,
              ),
            ),

            child:
                Column(

              children: [

                // ------------------------------------------
                // PICKUP
                // ------------------------------------------

                _BookingLocationRow(
                  iconColor:
                      AppColors.primary,

                  title:
                      'PICKUP',

                  badge:
                      'CURRENT',

                  value:
                      'Koramangala, Bengaluru',

                  mobile:
                      mobile,

                  trailing:
                      Icons
                          .my_location_rounded,
                ),


                Padding(

                  padding:
                      EdgeInsets.symmetric(
                    vertical:
                        mobile
                            ? 6
                            : 8,
                  ),

                  child:
                      const Divider(
                    height:
                        1,
                  ),
                ),


                // ------------------------------------------
                // DESTINATION
                // ------------------------------------------

                _BookingLocationRow(
                  iconColor:
                      AppColors.secondary,

                  title:
                      'DROP-OFF HOSPITAL',

                  value:
                      'Manipal Hospital, Old Airport Road',

                  mobile:
                      mobile,

                  trailing:
                      Icons
                          .swap_vert_rounded,
                ),
              ],
            ),
          ),


          SizedBox(
            height:
                mobile
                    ? 10
                    : 16,
          ),


          // ==================================================
          // SCHEDULE CHIPS
          // ==================================================

          SizedBox(

            height:
                mobile
                    ? 30
                    : 36,

            child:
                ListView.separated(

              scrollDirection:
                  Axis.horizontal,

              physics:
                  const BouncingScrollPhysics(),

              itemCount:
                  _chips.length,

              separatorBuilder:
                  (
                    context,
                    index,
                  ) =>
                      SizedBox(
                width:
                    mobile
                        ? 5
                        : 8,
              ),

              itemBuilder:
                  (
                    context,
                    index,
                  ) {

                final selected =
                    _selectedChip ==
                        index;

                return Material(

                  color:
                      selected
                          ? AppColors
                              .surfaceContainerLowest
                          : AppColors
                              .surfaceContainer,

                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.pill,
                  ),

                  child:
                      InkWell(

                    borderRadius:
                        BorderRadius.circular(
                      AppRadius.pill,
                    ),

                    onTap:
                        () {
                      setState(
                        () {
                          _selectedChip =
                              index;
                        },
                      );
                    },

                    child:
                        Container(

                      padding:
                          EdgeInsets.symmetric(
                        horizontal:
                            mobile
                                ? 10
                                : 16,

                        vertical:
                            mobile
                                ? 5
                                : 8,
                      ),

                      decoration:
                          BoxDecoration(

                        borderRadius:
                            BorderRadius.circular(
                          AppRadius.pill,
                        ),

                        border:
                            selected
                                ? Border.all(
                                    color:
                                        AppColors
                                            .primary
                                            .withValues(
                                          alpha: 0.5
                                    ),
                                  )
                                : null,
                      ),

                      child:
                          Row(

                        mainAxisSize:
                            MainAxisSize.min,

                        children: [

                          if (index == 0) ...[

                            Icon(
                              Icons
                                  .bolt_rounded,

                              size:
                                  mobile
                                      ? 11
                                      : 16,

                              color:
                                  selected
                                      ? AppColors
                                          .primary
                                      : AppColors
                                          .textSecondary,
                            ),

                            SizedBox(
                              width:
                                  mobile
                                      ? 3
                                      : 4,
                            ),
                          ],

                          Text(

                            _chips[index],

                            style:
                                AppTextStyles
                                    .labelMedium
                                    .copyWith(

                              fontSize:
                                  mobile
                                      ? 7
                                      : null,

                              color:
                                  selected
                                      ? AppColors
                                          .primary
                                      : AppColors
                                          .textSecondary,

                              fontWeight:
                                  selected
                                      ? FontWeight
                                          .w700
                                      : FontWeight
                                          .w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),


          SizedBox(
            height:
                mobile
                    ? 10
                    : 20,
          ),


          // ==================================================
          // BOOKING CTA
          //
          // THIS IS THE IMPORTANT FIX.
          //
          // Previously:
          //
          // Row(
          //   text,
          //   AeroMedButton(expand: false)
          // )
          //
          // At 360px this caused RIGHT OVERFLOW.
          //
          // Now everything is vertical on mobile.
          // ==================================================

          if (mobile)

            Column(

              crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,

              children: [

                Text(
                  'REQUEST MEDICAL TRANSPORT',

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      AppTextStyles
                          .labelSmall
                          .copyWith(
                    fontSize:
                        7,
                  ),
                ),

                const SizedBox(
                  height:
                      2,
                ),

                Text(
                  'No price at request stage',

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      AppTextStyles
                          .bodySmall
                          .copyWith(
                    fontSize:
                        8,
                  ),
                ),

                const SizedBox(
                  height:
                      8,
                ),

                SizedBox(

                  width:
                      double.infinity,

                  child:
                      AeroMedButton(

                    label:
                        'Book Ambulance',

                    icon:
                        Icons
                            .arrow_forward_rounded,

                    expand:
                        true,

                    height:
                        42,

                    onTap:
                        widget.onBook,
                  ),
                ),
              ],
            )

          else

            Row(

              crossAxisAlignment:
                  CrossAxisAlignment
                      .center,

              children: [

                Expanded(

                  child:
                      Column(

                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      Text(
                        'REQUEST MEDICAL TRANSPORT',

                        maxLines:
                            1,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            AppTextStyles
                                .labelSmall,
                      ),

                      Text(
                        'No price at request stage',

                        maxLines:
                            1,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            AppTextStyles
                                .bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width:
                      12,
                ),

                SizedBox(

                  width:
                      180,

                  child:
                      AeroMedButton(

                    label:
                        'Book Ambulance',

                    icon:
                        Icons
                            .arrow_forward_rounded,

                    expand:
                        true,

                    height:
                        50,

                    onTap:
                        widget.onBook,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}


// ============================================================
// LOCATION ROW
// ============================================================

class _BookingLocationRow
    extends StatelessWidget {
  const _BookingLocationRow({
    required this.iconColor,
    required this.title,
    required this.value,
    required this.mobile,
    required this.trailing,
    this.badge,
  });

  final Color iconColor;
  final String title;
  final String value;
  final bool mobile;
  final IconData trailing;
  final String? badge;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment
              .start,

      children: [

        Container(
          width:
              mobile
                  ? 9
                  : 12,

          height:
              mobile
                  ? 9
                  : 12,

          margin:
              EdgeInsets.only(
            top:
                mobile
                    ? 5
                    : 4,
          ),

          decoration:
              BoxDecoration(
            color:
                iconColor,
            shape:
                BoxShape.circle,
          ),
        ),

        SizedBox(
          width:
              mobile
                  ? 8
                  : 12,
        ),

        Expanded(

          child:
              Column(

            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [

              Row(

                children: [

                  Text(
                    title,

                    style:
                        AppTextStyles
                            .labelSmall
                            .copyWith(
                      fontSize:
                          mobile
                              ? 6
                              : null,
                    ),
                  ),

                  if (badge !=
                      null) ...[

                    const SizedBox(
                      width:
                          5,
                    ),

                    Container(

                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal:
                            4,
                        vertical:
                            1,
                      ),

                      decoration:
                          BoxDecoration(

                        color:
                            AppColors
                                .surfaceContainerHigh,

                        borderRadius:
                            BorderRadius
                                .circular(
                          4,
                        ),
                      ),

                      child:
                          Text(

                        badge!,

                        style:
                            AppTextStyles
                                .labelSmall
                                .copyWith(
                          fontSize:
                              5.5,

                          color:
                              AppColors
                                  .primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(
                height:
                    2,
              ),

              Text(

                value,

                maxLines:
                    mobile
                        ? 2
                        : 1,

                overflow:
                    TextOverflow
                        .ellipsis,

                style:
                    AppTextStyles
                        .headlineSmall
                        .copyWith(

                  fontSize:
                      mobile
                          ? 9.5
                          : 16,

                  height:
                      mobile
                          ? 1.15
                          : null,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          width:
              4,
        ),

        Icon(
          trailing,

          size:
              mobile
                  ? 13
                  : 18,

          color:
              AppColors
                  .textSecondary,
        ),
      ],
    );
  }
}


// ============================================================
// EMERGENCY BANNER
// ============================================================

class _EmergencyBanner
    extends StatelessWidget {
  const _EmergencyBanner({
    required this.onEmergency,
    required this.isMobile,
  });

  final VoidCallback onEmergency;
  final bool isMobile;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(

      width:
          double.infinity,

      padding:
          EdgeInsets.all(
        isMobile
            ? 12
            : 18,
      ),

      decoration:
          BoxDecoration(

        color:
            AppColors.errorSoft,

        borderRadius:
            BorderRadius.circular(
          AppRadius.card,
        ),

        border:
            Border.all(
          color:
              AppColors.urgentRed
                  .withValues(
                alpha: 0.35
          ),
        ),
      ),

      child:
          Column(

        crossAxisAlignment:
            CrossAxisAlignment
                .stretch,

        children: [

          Row(

            crossAxisAlignment:
                CrossAxisAlignment
                    .center,

            children: [

              Container(

                width:
                    isMobile
                        ? 32
                        : 38,

                height:
                    isMobile
                        ? 32
                        : 38,

                decoration:
                    const BoxDecoration(
                  color:
                      AppColors
                          .errorContainer,
                  shape:
                      BoxShape.circle,
                ),

                child:
                    Icon(
                  Icons
                      .emergency_rounded,
                  color:
                      AppColors.error,
                  size:
                      isMobile
                          ? 17
                          : 20,
                ),
              ),

              const SizedBox(
                width:
                    9,
              ),

              Expanded(

                child:
                    Column(

                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [

                    Text(
                      'CRITICAL PRIORITY',

                      maxLines:
                          1,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          AppTextStyles
                              .labelSmall
                              .copyWith(
                        color:
                            AppColors
                                .urgentRed,
                        fontWeight:
                            FontWeight
                                .w800,
                        fontSize:
                            isMobile
                                ? 6.5
                                : null,
                      ),
                    ),

                    Text(
                      'Need immediate emergency dispatch?',

                      maxLines:
                          2,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          AppTextStyles
                              .bodyLarge
                              .copyWith(
                        fontWeight:
                            FontWeight
                                .w700,
                        fontSize:
                            isMobile
                                ? 10
                                : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
                10,
          ),


          // ==================================================
          // MOBILE BUTTONS
          // ==================================================

          if (isMobile)

            Column(

              crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,

              children: [

                SizedBox(
                  height:
                      39,

                  child:
                      ElevatedButton.icon(

                    style:
                        ElevatedButton
                            .styleFrom(

                      backgroundColor:
                          AppColors
                              .urgentRed,

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          AppRadius
                              .pill,
                        ),
                      ),
                    ),

                    icon:
                        const Icon(
                      Icons
                          .emergency_rounded,
                      size:
                          16,
                    ),

                    label:
                        const Text(
                      'Request Emergency',
                    ),

                    onPressed:
                        onEmergency,
                  ),
                ),

                const SizedBox(
                  height:
                      6,
                ),

                SizedBox(
                  height:
                      36,

                  child:
                      OutlinedButton.icon(

                    style:
                        OutlinedButton
                            .styleFrom(

                      side:
                          BorderSide(
                        color:
                            AppColors
                                .outlineVariant,
                      ),

                      foregroundColor:
                          AppColors
                              .textPrimary,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          AppRadius
                              .pill,
                        ),
                      ),
                    ),

                    icon:
                        const Icon(
                      Icons
                          .phone_rounded,
                      size:
                          14,
                    ),

                    label:
                        const Text(
                      '112 SOS',
                    ),

                    onPressed:
                        onEmergency,
                  ),
                ),
              ],
            )

          else

            Row(
              children: [

                Expanded(
                  flex:
                      2,

                  child:
                      ElevatedButton.icon(

                    style:
                        ElevatedButton
                            .styleFrom(

                      backgroundColor:
                          AppColors
                              .urgentRed,

                      foregroundColor:
                          Colors.white,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          AppRadius
                              .pill,
                        ),
                      ),

                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical:
                            13,
                      ),
                    ),

                    icon:
                        const Icon(
                      Icons
                          .emergency_rounded,
                      size:
                          18,
                    ),

                    label:
                        Text(
                      'Request Emergency',
                      style:
                          AppTextStyles
                              .labelMedium
                              .copyWith(
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    onPressed:
                        onEmergency,
                  ),
                ),

                const SizedBox(
                  width:
                      10,
                ),

                Expanded(
                  child:
                      OutlinedButton.icon(

                    style:
                        OutlinedButton
                            .styleFrom(

                      side:
                          BorderSide(
                        color:
                            AppColors
                                .outlineVariant,
                      ),

                      foregroundColor:
                          AppColors
                              .textPrimary,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          AppRadius
                              .pill,
                        ),
                      ),

                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical:
                            13,
                      ),
                    ),

                    icon:
                        const Icon(
                      Icons
                          .phone_rounded,
                      size:
                          16,
                    ),

                    label:
                        const Text(
                      '112 SOS',
                    ),

                    onPressed:
                        onEmergency,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}


// ============================================================
// QUICK SERVICES
// ============================================================

class _QuickServicesGrid
    extends StatelessWidget {
  const _QuickServicesGrid({
    required this.onBook,
    required this.onTrack,
    required this.onBookings,
    required this.onQuotations,
    required this.isMobile,
  });

  final VoidCallback onBook;
  final VoidCallback onTrack;
  final VoidCallback onBookings;
  final VoidCallback onQuotations;
  final bool isMobile;


  @override
  Widget build(
    BuildContext context,
  ) {
    return GridView.count(

      shrinkWrap:
          true,

      physics:
          const NeverScrollableScrollPhysics(),

      crossAxisCount:
          2,

      mainAxisSpacing:
          isMobile
              ? 8
              : 12,

      crossAxisSpacing:
          isMobile
              ? 8
              : 12,

      childAspectRatio:
          isMobile
              ? 1.12
              : 1.25,

      children: [

        _ServiceTile(
          icon:
              Icons.local_hospital_rounded,
          title:
              'Book Transfer',
          subtitle:
              'Air or ground ICU',
          onTap:
              onBook,
          isMobile:
              isMobile,
        ),

        _ServiceTile(
          icon:
              Icons.radar_rounded,
          title:
              'Track Fleet',
          subtitle:
              'Real-time GPS nodes',
          onTap:
              onTrack,
          isMobile:
              isMobile,
        ),

        _ServiceTile(
          icon:
              Icons
                  .confirmation_number_rounded,
          title:
              'My Bookings',
          subtitle:
              'Active and completed trips',
          onTap:
              onBookings,
          isMobile:
              isMobile,
        ),

        _ServiceTile(
          icon:
              Icons.receipt_long_rounded,
          title:
              'Invoices & Docs',
          subtitle:
              'Insurance claims & bills',
          onTap:
              onQuotations,
          isMobile:
              isMobile,
        ),
      ],
    );
  }
}


// ============================================================
// SERVICE TILE
// ============================================================

class _ServiceTile
    extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isMobile,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isMobile;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(

      color:
          AppColors
              .surfaceContainer,

      borderRadius:
          BorderRadius.circular(
        isMobile
            ? 15
            : 20,
      ),

      child:
          InkWell(

        borderRadius:
            BorderRadius.circular(
          isMobile
              ? 15
              : 20,
        ),

        onTap:
            onTap,

        child:
            Padding(

          padding:
              EdgeInsets.all(
            isMobile
                ? 10
                : 16,
          ),

          child:
              Column(

            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [

              Container(

                width:
                    isMobile
                        ? 32
                        : 42,

                height:
                    isMobile
                        ? 32
                        : 42,

                decoration:
                    BoxDecoration(

                  color:
                      AppColors
                          .surfaceContainerHighest,

                  borderRadius:
                      BorderRadius.circular(
                    isMobile
                        ? 9
                        : 12,
                  ),
                ),

                child:
                    Icon(
                  icon,
                  color:
                      AppColors.primary,
                  size:
                      isMobile
                          ? 17
                          : 22,
                ),
              ),

              Column(

                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Text(

                    title,

                    maxLines:
                        1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        AppTextStyles
                            .bodyLarge
                            .copyWith(

                      fontWeight:
                          FontWeight
                              .w700,

                      fontSize:
                          isMobile
                              ? 9
                              : null,
                    ),
                  ),

                  const SizedBox(
                    height:
                        2,
                  ),

                  Text(

                    subtitle,

                    maxLines:
                        2,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        AppTextStyles
                            .caption
                            .copyWith(

                      color:
                          AppColors
                              .textSecondary,

                      fontSize:
                          isMobile
                              ? 6.5
                              : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ============================================================
// LEAD PARAMEDIC
// ============================================================

class _LeadParamedicCard
    extends StatelessWidget {
  const _LeadParamedicCard({
    required this.isMobile,
  });

  final bool isMobile;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(

      width:
          double.infinity,

      padding:
          EdgeInsets.all(
        isMobile
            ? 11
            : 16,
      ),

      decoration:
          BoxDecoration(

        color:
            AppColors
                .surfaceContainer,

        borderRadius:
            BorderRadius.circular(
          AppRadius.card,
        ),

        border:
            Border.all(
          color:
              AppColors
                  .outlineVariant,
        ),
      ),

      child:
          Row(

        children: [

          Container(

            width:
                isMobile
                    ? 38
                    : 48,

            height:
                isMobile
                    ? 38
                    : 48,

            decoration:
                BoxDecoration(

              shape:
                  BoxShape.circle,

              color:
                  AppColors
                      .surfaceContainerHighest,

              border:
                  Border.all(
                color:
                    AppColors
                        .primary
                        .withValues(
                      alpha: 0.5
                ),

                width:
                    1.5,
              ),
            ),

            child:
                Icon(

              Icons
                  .person_pin_rounded,

              color:
                  AppColors.primary,

              size:
                  isMobile
                      ? 22
                      : 28,
            ),
          ),

          SizedBox(
            width:
                isMobile
                    ? 9
                    : 14,
          ),

          Expanded(

            child:
                Column(

              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                Text(

                  'LEAD PARAMEDIC ASSIGNED',

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      AppTextStyles
                          .labelSmall
                          .copyWith(

                    color:
                        AppColors
                            .primary,

                    fontWeight:
                        FontWeight
                            .w700,

                    fontSize:
                        isMobile
                            ? 6
                            : null,
                  ),
                ),

                const SizedBox(
                  height:
                      2,
                ),

                Text(

                  'Dr. Ananya Ray, ALS',

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      AppTextStyles
                          .headlineSmall
                          .copyWith(

                    fontSize:
                        isMobile
                            ? 10
                            : 15,

                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),

                Text(

                  'Manipal Critical Response Team',

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      AppTextStyles
                          .bodySmall
                          .copyWith(

                    color:
                        AppColors
                            .textSecondary,

                    fontSize:
                        isMobile
                            ? 7
                            : null,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            width:
                isMobile
                    ? 34
                    : 40,

            height:
                isMobile
                    ? 34
                    : 40,

            child:
                Material(

              color:
                  AppColors
                      .surfaceContainerHigh,

              shape:
                  const CircleBorder(),

              child:
                  InkWell(

                customBorder:
                    const CircleBorder(),

                onTap:
                    () {},

                child:
                    Icon(
                  Icons
                      .phone_in_talk_rounded,
                  color:
                      AppColors
                          .primary,
                  size:
                      isMobile
                          ? 16
                          : 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}