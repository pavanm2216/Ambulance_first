import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/customer_care_case.dart';
import '../../../../core/services/customer_care_repository.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';
import '../widgets/agent_shift_banner.dart';
import '../widgets/kpi_queue_card.dart';
import '../widgets/triage_incident_card.dart';
import '../widgets/telemetry_radar_card.dart';

class CustomerCareDashboardScreen extends StatefulWidget {
  const CustomerCareDashboardScreen({
    super.key,
    required this.onNavigateToCallVerify,
    required this.onNavigateToDetails,
    required this.onNavigateToNewIntake,
    required this.onNavigateToPending,
    required this.onNavigateToVerified,
    required this.onNavigateToHandoff,
    required this.onShowToast,
  });

  final ValueChanged<CustomerCareCase> onNavigateToCallVerify;
  final ValueChanged<CustomerCareCase> onNavigateToDetails;
  final VoidCallback onNavigateToNewIntake;
  final VoidCallback onNavigateToPending;
  final VoidCallback onNavigateToVerified;
  final VoidCallback onNavigateToHandoff;
  final ValueChanged<String> onShowToast;

  @override
  State<CustomerCareDashboardScreen> createState() =>
      _CustomerCareDashboardScreenState();
}

class _CustomerCareDashboardScreenState
    extends State<CustomerCareDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _handoffsInProgress = <String>{};
  String _selectedFilter = 'All';
  String _kpiFilter = 'all'; // 'all', 'new', 'pending', 'verified', 'lead'

  String get _backendFilter {
    switch (_selectedFilter) {
      case 'Code Red':
        return 'CODE_RED';
      case 'High Urgency':
        return 'HIGH';
      case 'Pediatric':
        return 'PEDIATRIC';
      case 'ICU Required':
        return 'ICU';
      default:
        return 'ALL';
    }
  }

  Future<void> _selectKpiFilter(String key, String backendFilter) async {
    final selected = _kpiFilter == key;
    setState(() => _kpiFilter = selected ? 'all' : key);
    try {
      await CustomerCareRepository.instance.load(
        filter: selected ? _backendFilter : backendFilter,
        search: _searchController.text,
      );
    } catch (error) {
      widget.onShowToast('Queue refresh failed: $error');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleHandoff(CustomerCareCase item) async {
    if (_handoffsInProgress.contains(item.id)) return;

    final repo = CustomerCareRepository.instance;
    try {
      // This button is rendered only for cases whose canonical list status is
      // VERIFIED. Do not re-read the presentation/details RPC here: that RPC
      // does not reliably contain bookings.status and was the source of the
      // false "Booking must be verified" message. The handoff RPC itself is
      // authoritative and enforces the VERIFIED transition server-side.
      final canonicalStatus = item.status.trim().toUpperCase();
      debugPrint('CC DASHBOARD HANDOFF BOOKING ID: ${item.id}');
      debugPrint('CC DASHBOARD HANDOFF BOOKING STATUS: "$canonicalStatus"');
      if (canonicalStatus != 'VERIFIED') {
        widget.onShowToast(
          'This booking is not currently VERIFIED in the Customer Care queue.',
        );
        return;
      }

      setState(() => _handoffsInProgress.add(item.id));
      debugPrint(
        'CC HANDOFF START: bookingId=${item.id} status=$canonicalStatus',
      );
      final success = await repo.sendCustomerCareToTeamLead(
        item.id,
        item.notes,
      );
      debugPrint('CC HANDOFF RESULT: $success');
      if (success) {
        widget.onShowToast(
          'Booking #${item.id} sent to Team Lead successfully.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('CC HANDOFF ERROR: $error');
      debugPrint('$stackTrace');
      widget.onShowToast('Handoff failed: $error');
    } finally {
      if (mounted) {
        setState(() => _handoffsInProgress.remove(item.id));
      }
    }
  }

  List<CustomerCareCase> _getFilteredCases(List<CustomerCareCase> cases) {
    final query = _searchController.text.trim().toLowerCase();

    return cases.where((c) {
      // Apply KPI queue filter
      if (_kpiFilter == 'new') {
        if (c.status != 'NEW' && c.status != 'CUSTOMER_CARE_CONTACT_PENDING') {
          return false;
        }
      } else if (_kpiFilter == 'pending') {
        if (c.status != 'NEW' &&
            c.status != 'CUSTOMER_CARE_CONTACT_PENDING' &&
            c.status != 'CUSTOMER_CARE_CONTACTED' &&
            c.status != 'VERIFICATION_PENDING') {
          return false;
        }
      } else if (_kpiFilter == 'verified') {
        if (c.status != 'VERIFIED') return false;
      } else if (_kpiFilter == 'lead') {
        if (c.status != 'SENT_TO_TEAM_LEAD' &&
            c.status != 'ALLOCATION_PENDING' &&
            c.status != 'ASSIGNED') {
          return false;
        }
      }

      // Apply chip filter
      if (_selectedFilter == 'Code Red' && !c.isCodeRed) {
        return false;
      }
      if (_selectedFilter == 'High Urgency' &&
          c.priority != 'HIGH' &&
          !c.isCodeRed) {
        return false;
      }
      if (_selectedFilter == 'Pediatric' && !c.pediatric) return false;
      if (_selectedFilter == 'ICU Required' && !c.icu) return false;

      // Apply text query
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
        if (repo.errorMessage != null && repo.allCases.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Customer Care data unavailable: ${repo.errorMessage}',
              ),
            ),
          );
        }
        if (repo.isLoading && repo.allCases.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final allCases = repo.allCases;
        final newInboundCount = repo.newInboundCount;
        final pendingCallsCount = repo.pendingCallsCount;
        final verifiedCount = repo.verifiedCount;
        final handedOverCount = repo.handedOverCount;

        final filteredCases = _getFilteredCases(allCases);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Agent Shift Protocol Banner
              const AgentShiftBanner(),
              const SizedBox(height: 12),

              // 2. Interactive KPI Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 580;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: isWide ? 1.6 : 1.3,
                    children: [
                      KpiQueueCard(
                        title: 'New Inbound',
                        count: newInboundCount.toString().padLeft(2, '0'),
                        badgeText: '${repo.codeRedCount} Code Red',
                        subtitle: 'Requires rapid pickup',
                        accentColor: CustomerCareColors.error,
                        badgeBgColor: CustomerCareColors.errorContainer,
                        badgeFgColor: CustomerCareColors.onErrorContainer,
                        hasPulse: true,
                        isSelected: _kpiFilter == 'new',
                        onTap: () {
                          _selectKpiFilter('new', 'NEW');
                          widget.onShowToast('Filtered Queue: New Inbound');
                        },
                      ),
                      KpiQueueCard(
                        title: 'Pending Calls',
                        count: pendingCallsCount.toString().padLeft(2, '0'),
                        badgeText: '$pendingCallsCount Follow-up',
                        subtitle: 'Avg wait 1.8m',
                        accentColor: CustomerCareColors.warning,
                        badgeBgColor: CustomerCareColors.warningContainer,
                        badgeFgColor: CustomerCareColors.onWarningContainer,
                        icon: Icons.ring_volume_rounded,
                        isSelected: _kpiFilter == 'pending',
                        onTap: () {
                          _selectKpiFilter('pending', 'PENDING_CALLS');
                          widget.onShowToast('Filtered Queue: Pending Calls');
                        },
                      ),
                      KpiQueueCard(
                        title: 'Verified',
                        count: verifiedCount.toString().padLeft(2, '0'),
                        badgeText: 'Ready',
                        subtitle: 'For Team Lead',
                        accentColor: CustomerCareColors.secondary,
                        badgeBgColor: CustomerCareColors.secondaryContainer,
                        badgeFgColor:
                            CustomerCareColors.onSecondaryFixedVariant,
                        icon: Icons.task_alt_rounded,
                        isSelected: _kpiFilter == 'verified',
                        onTap: () {
                          _selectKpiFilter('verified', 'VERIFIED');
                          widget.onShowToast('Filtered Queue: Verified Cases');
                        },
                      ),
                      KpiQueueCard(
                        title: 'Sent to Lead',
                        count: handedOverCount.toString().padLeft(2, '0'),
                        badgeText: 'In Dispatch',
                        subtitle: 'Downstream active',
                        accentColor: CustomerCareColors.primaryContainer,
                        badgeBgColor: CustomerCareColors.primaryFixed,
                        badgeFgColor: CustomerCareColors.onPrimaryFixedVariant,
                        icon: Icons.outbox_rounded,
                        isSelected: _kpiFilter == 'lead',
                        onTap: () {
                          _selectKpiFilter('lead', 'SENT_TO_TEAM_LEAD');
                          widget.onShowToast(
                            'Filtered Queue: Handed Over to Lead',
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // 3. Operational Search & Filter Ribbon
              Container(
                decoration: BoxDecoration(
                  color: CustomerCareColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CustomerCareColors.outlineVariant,
                    width: 0.8,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) async {
                    setState(() {});
                    try {
                      await CustomerCareRepository.instance.load(
                        filter: _backendFilter,
                        search: value,
                      );
                    } catch (error) {
                      widget.onShowToast('Search failed: $error');
                    }
                  },
                  style: CustomerCareTextStyles.bodyMd,
                  decoration: InputDecoration(
                    hintText: 'Search Booking ID, patient, caller phone...',
                    hintStyle: CustomerCareTextStyles.bodyMd.copyWith(
                      color: CustomerCareColors.onSurfaceVariant,
                    ),
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
                              CustomerCareRepository.instance
                                  .load(filter: _backendFilter)
                                  .catchError(
                                    (error) => widget.onShowToast(
                                      'Search reset failed: $error',
                                    ),
                                  );
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', allCases.length.toString()),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'Code Red',
                      repo.codeRedCount.toString(),
                      dotColor: CustomerCareColors.error,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'High Urgency',
                      repo.highPriorityCount.toString(),
                      dotColor: CustomerCareColors.warning,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'Pediatric',
                      repo.pediatricCount.toString(),
                      icon: Icons.child_care,
                    ),
                    const SizedBox(width: 6),
                    _buildFilterChip('ICU Required', repo.icuCount.toString()),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Incident Queue Header
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emergency_outlined,
                          size: 18,
                          color: CustomerCareColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Triage Incident Queue',
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
                  Flexible(
                    child: Text(
                      repo.isLoading ? 'Syncing...' : 'Synced from Supabase',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: CustomerCareTextStyles.labelSm.copyWith(
                        color: CustomerCareColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 5. Incident Queue Cards List
              if (filteredCases.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: CustomerCareColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CustomerCareColors.outlineVariant,
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 36,
                        color: CustomerCareColors.secondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No Incidents in Selected Queue',
                        style: CustomerCareTextStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All cases matching this filter have been triaged or handed over.',
                        style: CustomerCareTextStyles.bodySm.copyWith(
                          color: CustomerCareColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
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
                    return TriageIncidentCard(
                      caseItem: item,
                      onCallVerify: () => widget.onNavigateToCallVerify(item),
                      onCallPhone: () async {
                        final phone = item.mobileNumber.replaceAll(
                          RegExp(r'[^0-9+]'),
                          '',
                        );
                        final launched = await launchUrl(
                          Uri(scheme: 'tel', path: phone),
                        );
                        if (!launched) {
                          widget.onShowToast(
                            'Unable to open the phone dialer for ${item.mobileNumber}.',
                          );
                        }
                      },
                      onViewDetails: () => widget.onNavigateToDetails(item),
                      onSendToTeamLead: () => _handleHandoff(item),
                    );
                  },
                ),
              const SizedBox(height: 14),

              // 6. Air Corridor Airspaces Radar Delight Component
              TelemetryRadarCard(
                onTap: () {
                  final activeCase =
                      repo.activeTripCases.firstOrNull ??
                      (allCases.isEmpty ? null : allCases.first);
                  if (activeCase != null) {
                    widget.onNavigateToDetails(activeCase);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    String count, {
    Color? dotColor,
    IconData? icon,
  }) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = label);
        CustomerCareRepository.instance
            .load(filter: _backendFilter, search: _searchController.text)
            .catchError((error) => widget.onShowToast('Filter failed: $error'));
        widget.onShowToast('Filter applied: $label');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? CustomerCareColors.primaryContainer
              : CustomerCareColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? CustomerCareColors.primaryContainer
                : CustomerCareColors.outlineVariant,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 5),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.white : CustomerCareColors.tertiary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: CustomerCareTextStyles.labelSm.copyWith(
                color: isSelected ? Colors.white : CustomerCareColors.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : CustomerCareColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: CustomerCareTextStyles.labelSm.copyWith(
                  color: isSelected
                      ? Colors.white
                      : CustomerCareColors.onSurfaceVariant,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
