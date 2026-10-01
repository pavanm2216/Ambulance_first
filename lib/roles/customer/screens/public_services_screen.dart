import 'package:flutter/material.dart';
import '../../../shared/widgets/aeromed_page.dart';
import '../../../shared/widgets/aeromed_service_card.dart';
import '../../../shared/widgets/motion.dart';

class PublicServicesPage extends StatelessWidget {
  const PublicServicesPage({super.key});

  static const _services = [
    (Icons.local_hospital_rounded, 'Emergency Ambulance', '24/7 emergency response and patient transport.'),
    (Icons.airport_shuttle_outlined, 'Patient Transport', 'Non-emergency transfers between home and hospitals.'),
    (Icons.local_hotel_outlined, 'ICU Ambulance', 'Ventilator and critical-care monitoring on board.'),
    (Icons.flight_takeoff_rounded, 'Airport Medical Transfer', 'Supported transfers for patients travelling by air.'),
    (Icons.medical_services_rounded, 'Medical Escort', 'Trained medical support for eligible journeys.'),
    (Icons.event_available_rounded, 'Event Medical Support', 'On-site ambulance support for public and private events.'),
    (Icons.accessible_forward_rounded, 'Special Patient Care', 'Transport options for patients needing additional assistance.'),
  ];

  @override
  Widget build(BuildContext context) {
    return AeroMedPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AeroMedPageHeader(title: 'Public Services', subtitle: 'Explore Ambulance First services available to customers.'),
          const SizedBox(height: 18),
          ..._services.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FadeSlideIn(
                    delay: Duration(milliseconds: 40 * entry.key),
                    child: AeroMedServiceCard(
                      icon: entry.value.$1,
                      title: entry.value.$2,
                      description: entry.value.$3,
                      onTap: () => _showService(context, entry.value.$2, entry.value.$3),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void _showService(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text('$description\n\nUse Book Ambulance to submit a request, or contact customer support for assistance.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
