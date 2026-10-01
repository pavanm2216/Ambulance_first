import 'package:flutter/material.dart';
import '../../../../core/models/customer_care_case.dart';
import '../../../../core/services/customer_care_repository.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class AllBookingsArchiveScreen extends StatefulWidget {
  const AllBookingsArchiveScreen({
    super.key,
    required this.onViewDetails,
  });

  final ValueChanged<CustomerCareCase> onViewDetails;

  @override
  State<AllBookingsArchiveScreen> createState() => _AllBookingsArchiveScreenState();
}

class _AllBookingsArchiveScreenState extends State<AllBookingsArchiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedService = 'All';
  String _selectedStatus = 'All';

  final List<String> _serviceCategories = [
    'All',
    'Road',
    'Railway',
    'Air',
    'Dead Body Transport',
  ];

  final List<String> _statuses = [
    'All',
    'New',
    'Verified',
    'Sent to Team Lead',
    'In Transit',
    'Completed',
    'Cancelled',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedService = 'All';
      _selectedStatus = 'All';
    });
  }

  List<CustomerCareCase> _applyFilters(List<CustomerCareCase> list) {
    final query = _searchController.text.trim().toLowerCase();

    return list.where((c) {
      // Service filter
      if (_selectedService == 'Road' && c.serviceCategory != 'ROAD') return false;
      if (_selectedService == 'Railway' && c.serviceCategory != 'TRAIN') return false;
      if (_selectedService == 'Air' && c.serviceCategory != 'AIR') return false;
      if (_selectedService == 'Dead Body Transport' &&
          c.serviceCategory != 'DEAD_BODY' &&
          !c.condition.toLowerCase().contains('mortuary')) {
        return false;
      }

      // Status filter
      if (_selectedStatus == 'New' && c.status != 'NEW') return false;
      if (_selectedStatus == 'Verified' && c.status != 'VERIFIED') return false;
      if (_selectedStatus == 'Sent to Team Lead' && c.status != 'SENT_TO_TEAM_LEAD') return false;
      if (_selectedStatus == 'In Transit' && c.status != 'IN_TRANSIT') return false;
      if (_selectedStatus == 'Completed' && c.status != 'SERVICE_COMPLETED') return false;
      if (_selectedStatus == 'Cancelled' && c.status != 'CANCELLED') return false;

      // Text query
      if (query.isNotEmpty) {
        final matchesId = c.id.toLowerCase().contains(query);
        final matchesPatient = c.patientName.toLowerCase().contains(query);
        final matchesCaller = c.customerName.toLowerCase().contains(query);
        final matchesPhone = c.mobileNumber.toLowerCase().contains(query);
        final matchesPickup = c.pickupAddress.toLowerCase().contains(query);
        final matchesDest = c.destinationAddress.toLowerCase().contains(query);
        if (!matchesId &&
            !matchesPatient &&
            !matchesCaller &&
            !matchesPhone &&
            !matchesPickup &&
            !matchesDest) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final repo = CustomerCareRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final allCases = repo.allCases;
        final filteredCases = _applyFilters(allCases);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Container(
                decoration: BoxDecoration(
                  color: CustomerCareColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.8),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_rounded,
                            size: 22,
                            color: CustomerCareColors.primaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Master Bookings Archive',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CustomerCareTextStyles.headlineSm.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Complete database of historical, active & verified cases',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: CustomerCareTextStyles.bodySm.copyWith(
                                    color: CustomerCareColors.onSurfaceVariant,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _clearFilters,
                      child: Text(
                        'Clear Filters',
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          color: CustomerCareColors.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Search Box
              Container(
                decoration: BoxDecoration(
                  color: CustomerCareColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.8),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: CustomerCareTextStyles.bodyMd,
                  decoration: InputDecoration(
                    hintText: 'Search by Booking ID, patient, caller phone...',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: CustomerCareColors.onSurfaceVariant,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Controls: Service & Status
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: CustomerCareColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedService,
                          isExpanded: true,
                          items: _serviceCategories.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(
                                'Service: $s',
                                style: CustomerCareTextStyles.bodySm.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedService = v);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: CustomerCareColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          isExpanded: true,
                          items: _statuses.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(
                                'Status: $s',
                                style: CustomerCareTextStyles.bodySm.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedStatus = v);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Results Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Showing ${filteredCases.length} of ${allCases.length} records',
                  style: CustomerCareTextStyles.labelSm.copyWith(
                    color: CustomerCareColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Table / Card List
              if (filteredCases.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: CustomerCareColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 36,
                        color: CustomerCareColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No Records Match the Given Criteria',
                        style: CustomerCareTextStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try clearing the filters or searching with a different term.',
                        style: CustomerCareTextStyles.bodySm.copyWith(
                          color: CustomerCareColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredCases.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filteredCases[index];
                    return _ArchiveCard(
                      caseItem: item,
                      onTap: () => widget.onViewDetails(item),
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

class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({
    required this.caseItem,
    required this.onTap,
  });

  final CustomerCareCase caseItem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: CustomerCareColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CustomerCareColors.outlineVariant, width: 0.8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          style: CustomerCareTextStyles.telemetryDisplay.copyWith(
                            fontSize: 14,
                            color: CustomerCareColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: CustomerCareColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            caseItem.createdAt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CustomerCareTextStyles.labelSm.copyWith(fontSize: 9.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: CustomerCareColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        caseItem.statusLabel.toUpperCase(),
                        maxLines: 1,
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${caseItem.patientName} (${caseItem.age} ${caseItem.gender}) • Caller: ${caseItem.customerName}',
              style: CustomerCareTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              '${caseItem.pickupAddress} → ${caseItem.destinationHospital.isNotEmpty ? caseItem.destinationHospital : caseItem.destinationAddress}',
              style: CustomerCareTextStyles.bodySm.copyWith(
                color: CustomerCareColors.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Service: ${caseItem.serviceCategory} • Acuity: ${caseItem.priorityLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CustomerCareTextStyles.labelSm.copyWith(
                      color: CustomerCareColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: CustomerCareColors.outline),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
