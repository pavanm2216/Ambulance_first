import 'package:flutter/material.dart';
import '../../theme/driver_colors.dart';
import '../../theme/driver_text_styles.dart';

class LiveMapViewport extends StatefulWidget {
  const LiveMapViewport({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    this.latitude,
    this.longitude,
    this.isLocationAvailable = true,
    this.heading = 0,
    this.corridorName = 'ROUTE PROVIDER NOT RECORDED',
    this.nextTurnInstruction = 'Destination details are not recorded.',
    this.targetLabel = 'DESTINATION',
    this.onNavigate,
  });

  final String pickupAddress;
  final String destinationAddress;
  final double? latitude;
  final double? longitude;
  final bool isLocationAvailable;
  final double heading;
  final String corridorName;
  final String nextTurnInstruction;
  final String targetLabel;
  final VoidCallback? onNavigate;

  @override
  State<LiveMapViewport> createState() => _LiveMapViewportState();
}

class _LiveMapViewportState extends State<LiveMapViewport>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: DriverColors.inverseSurfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DriverColors.hudBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            // Tactical Dark Map Canvas
            CustomPaint(
              size: Size.infinite,
              painter: _TacticalGridPainter(),
            ),

            if (!widget.isLocationAvailable) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: DriverColors.inverseSurface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DriverColors.tertiary),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_off_rounded, color: DriverColors.tertiary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'LOCATION UNAVAILABLE',
                        style: DriverTextStyles.telemetrySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Route Line Path
              CustomPaint(
                size: Size.infinite,
                painter: _TacticalRoutePainter(),
              ),

              // Animated Pulsing Ambulance GPS Marker
              Positioned(
                left: 120,
                top: 100,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: DriverColors.primaryContainer.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: DriverColors.primaryContainer,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: DriverColors.primaryContainer.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: (widget.heading - 90) * (3.1415926535 / 180),
                            child: const Icon(Icons.navigation, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Current route target marker: pickup first, then drop-off.
              Positioned(
                right: 50,
                top: 55,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: DriverColors.tertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.targetLabel,
                        style: DriverTextStyles.telemetryMicro.copyWith(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      widget.targetLabel == 'PICKUP'
                          ? Icons.person_pin_circle_rounded
                          : Icons.local_hospital_rounded,
                      color: DriverColors.tertiary,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ],

            // Top Corridor Pill Overlay
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: DriverColors.inverseSurface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DriverColors.secondary, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: DriverColors.secondaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.corridorName,
                          style: DriverTextStyles.telemetryMicro.copyWith(
                            color: DriverColors.secondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: widget.onNavigate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DriverColors.inverseSurface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DriverColors.hudBorder),
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Instruction Banner
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: InkWell(
                onTap: widget.onNavigate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: DriverColors.inverseSurface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DriverColors.hudBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DriverColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.turn_right_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.nextTurnInstruction,
                            style: DriverTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${widget.targetLabel}: ${widget.destinationAddress}',
                            style: DriverTextStyles.telemetryMicro.copyWith(
                              color: DriverColors.outlineVariant,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TacticalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF1E2D3D)
      ..strokeWidth = 1.0;

    const spacing = 35.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TacticalRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final corridorPaint = Paint()
      ..color = DriverColors.secondary.withValues(alpha: 0.3)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = DriverColors.secondaryContainer
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(40, 190);
    path.lineTo(135, 115);
    path.lineTo(210, 115);
    path.lineTo(size.width - 65, 75);

    canvas.drawPath(path, corridorPaint);
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
