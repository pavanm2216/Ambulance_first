import 'package:flutter/material.dart';
import '../../core/models/booking.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import './aeromed_card.dart';
import './aeromed_status_badge.dart';

/// A single pickup/destination row with its own icon — used inside
/// [AeroMedBookingCard] and the active-trip screen.
class AeroMedLocationCard extends StatelessWidget {
  const AeroMedLocationCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyStrong, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

/// The booking summary card used on the Dashboard, My Bookings, and
/// Booking History screens.
class AeroMedBookingCard extends StatelessWidget {
  const AeroMedBookingCard({super.key, required this.booking, this.onTap});

  final Booking booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AeroMedCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(booking.id, style: AppTextStyles.cardTitle.copyWith(fontSize: 16))),
              AeroMedStatusBadge(booking.status, live: booking.status == 'On the Way'),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 14),
          AeroMedLocationCard(icon: Icons.radio_button_checked_rounded, label: 'Pickup', value: booking.pickup),
          const SizedBox(height: 12),
          AeroMedLocationCard(
            icon: Icons.location_on_rounded,
            label: 'Destination',
            value: booking.destination,
            iconColor: AppColors.primaryDark,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('${booking.date} • ${booking.time}', style: AppTextStyles.supporting),
              const Spacer(),
              Text(booking.formattedAmount, style: AppTextStyles.cardTitle),
            ],
          ),
        ],
      ),
    );
  }
}
