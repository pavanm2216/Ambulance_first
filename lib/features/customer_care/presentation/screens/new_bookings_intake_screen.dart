import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/customer_care_case.dart';
import '../../../../core/services/customer_care_repository.dart';
import '../../theme/customer_care_colors.dart';
import '../../theme/customer_care_text_styles.dart';

class NewBookingsIntakeScreen extends StatefulWidget {
  const NewBookingsIntakeScreen({
    super.key,
    required this.onStartCallVerify,
    required this.onShowToast,
  });

  final ValueChanged<CustomerCareCase> onStartCallVerify;
  final ValueChanged<String> onShowToast;

  @override
  State<NewBookingsIntakeScreen> createState() =>
      _NewBookingsIntakeScreenState();
}

class _NewBookingsIntakeScreenState extends State<NewBookingsIntakeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All New';
  int _timerSeconds = 14;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _timerSeconds = (_timerSeconds + 1) % 60;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerCareCase> _getFilteredCases(List<CustomerCareCase> cases) {
    final query = _searchController.text.trim().toLowerCase();

    return cases.where((c) {
      // Must be new or contact pending
      final isNew =
          c.status == 'NEW' || c.status == 'CUSTOMER_CARE_CONTACT_PENDING';
      if (!isNew) return false;

      // Filter chips
      if (_selectedFilter == 'Code Red' && !c.isCodeRed) return false;
      if (_selectedFilter == 'ICU/Ventilator' && !c.icu && !c.ventilator) {
        return false;
      }
      if (_selectedFilter == 'Pediatric' && !c.pediatric) return false;

      // Search text
      if (query.isNotEmpty) {
        final matchesId = c.id.toLowerCase().contains(query);
        final matchesPatient = c.patientName.toLowerCase().contains(query);
        final matchesCaller = c.customerName.toLowerCase().contains(query);
        final matchesPhone = c.mobileNumber.toLowerCase().contains(query);
        final matchesHospital = c.destinationHospital.toLowerCase().contains(
          query,
        );
        if (!matchesId &&
            !matchesPatient &&
            !matchesCaller &&
            !matchesPhone &&
            !matchesHospital) {
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
        final allNewCases = repo.allCases
            .where(
              (c) =>
                  c.status == 'NEW' ||
                  c.status == 'CUSTOMER_CARE_CONTACT_PENDING',
            )
            .toList();
        final filteredCases = _getFilteredCases(repo.allCases);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Rapid Response Mandate (SOP 04-B) Banner
              Container(
                decoration: BoxDecoration(
                  color: CustomerCareColors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: CustomerCareColors.error.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: CustomerCareColors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.timer_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'RAPID RESPONSE MANDATE',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: CustomerCareTextStyles.labelSm
                                          .copyWith(
                                            color: CustomerCareColors.error,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
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
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'SOP 04-B',
                                      style: CustomerCareTextStyles.labelSm
                                          .copyWith(
                                            color: CustomerCareColors.error,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9.5,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              RichText(
                                text: TextSpan(
                                  style: CustomerCareTextStyles.bodySm.copyWith(
                                    color: CustomerCareColors.onErrorContainer,
                                    fontSize: 11.5,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'Initial telephone patch-in mandatory within ',
                                    ),
                                    TextSpan(
                                      text: '180 seconds',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' of inbound request receipt.',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Countdown bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.65,
                        minHeight: 4,
                        backgroundColor: CustomerCareColors.error.withValues(
                          alpha: 0.2,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          CustomerCareColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Header & Timer
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Urgent Intake Queue',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CustomerCareTextStyles.headlineSm.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${allNewCases.length} Inbound Requests Pending Initial Customer Care Contact',
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
                  const SizedBox(width: 8),
                  Container(
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
                          Icons.sync,
                          size: 14,
                          color: CustomerCareColors.primaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '00:${_timerSeconds.toString().padLeft(2, "0")}s',
                          style: CustomerCareTextStyles.telemetryDisplay
                              .copyWith(
                                fontSize: 12,
                                color: CustomerCareColors.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 3. Search Input
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
                        filter: 'NEW',
                        search: value,
                      );
                    } catch (error) {
                      widget.onShowToast('Search failed: $error');
                    }
                  },
                  style: CustomerCareTextStyles.bodyMd,
                  decoration: InputDecoration(
                    hintText: 'Search Booking ID, caller phone, hospital...',
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 4. Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildIntakeFilterChip(
                      'All New',
                      allNewCases.length.toString(),
                    ),
                    const SizedBox(width: 6),
                    _buildIntakeFilterChip(
                      'Code Red',
                      allNewCases.where((c) => c.isCodeRed).length.toString(),
                      dotColor: CustomerCareColors.error,
                    ),
                    const SizedBox(width: 6),
                    _buildIntakeFilterChip(
                      'ICU/Ventilator',
                      allNewCases
                          .where((c) => c.icu || c.ventilator)
                          .length
                          .toString(),
                    ),
                    const SizedBox(width: 6),
                    _buildIntakeFilterChip(
                      'Pediatric',
                      allNewCases.where((c) => c.pediatric).length.toString(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 5. Intake Case Cards List
              if (filteredCases.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
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
                        'Intake Queue Clear',
                        style: CustomerCareTextStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All new inbound transport requests have been patched in and triaged.',
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
                    return _NewIntakeCard(
                      caseItem: item,
                      onStartCallVerify: () => widget.onStartCallVerify(item),
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

  Widget _buildIntakeFilterChip(String label, String count, {Color? dotColor}) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = label);
        widget.onShowToast('Filtered Intake: $label');
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

class _NewIntakeCard extends StatelessWidget {
  const _NewIntakeCard({
    required this.caseItem,
    required this.onStartCallVerify,
    required this.onCallPhone,
  });

  final CustomerCareCase caseItem;
  final VoidCallback onStartCallVerify;
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Urgency Top Bar
          Container(
            height: 3.5,
            width: double.infinity,
            color: caseItem.isCodeRed
                ? CustomerCareColors.error
                : CustomerCareColors.primaryContainer,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
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
                              style: CustomerCareTextStyles.telemetryDisplay
                                  .copyWith(
                                    fontSize: 14,
                                    color: CustomerCareColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '• Updated ${caseItem.updatedAt.isEmpty ? caseItem.createdAt : caseItem.updatedAt}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CustomerCareTextStyles.labelSm.copyWith(
                                color: CustomerCareColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (caseItem.isCodeRed) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                                  'CODE RED • URGENT',
                                  style: CustomerCareTextStyles.labelSm.copyWith(
                                    color: CustomerCareColors.onErrorContainer,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (caseItem.isDraft) ...[
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
                        Text(
                          'Submitted ${caseItem.submittedAt}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CustomerCareTextStyles.labelSm.copyWith(
                            color: CustomerCareColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 6),

                // Patient Info & Medical Scenario
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${caseItem.patientName}, ${caseItem.age}${caseItem.gender.isNotEmpty ? caseItem.gender[0].toUpperCase() : ""}',
                            style: CustomerCareTextStyles.headlineSm.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.medical_information,
                                size: 14,
                                color: caseItem.isCodeRed
                                    ? CustomerCareColors.error
                                    : CustomerCareColors.primary,
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
                                        : FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Caller Strip
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
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person,
                              size: 15,
                              color: CustomerCareColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Caller: ${caseItem.customerName} (${caseItem.relationship})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CustomerCareTextStyles.bodySm.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                caseItem.mobileNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CustomerCareTextStyles.telemetryDisplay.copyWith(
                                  fontSize: 11,
                                  color: CustomerCareColors.primaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: onCallPhone,
                              icon: const Icon(Icons.call, size: 12),
                              label: const Text('CALL NOW'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CustomerCareColors.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                textStyle: CustomerCareTextStyles.labelSm.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Route Snippet
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: CustomerCareColors.surfaceContainerHigh.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_hospital,
                        size: 13,
                        color: CustomerCareColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          caseItem.pickupAddress,
                          style: CustomerCareTextStyles.bodySm.copyWith(
                            fontSize: 11,
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
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        caseItem.distanceKm > 0
                            ? '${caseItem.distanceKm} km'
                            : 'Route unavailable',
                        style: CustomerCareTextStyles.labelSm.copyWith(
                          color: CustomerCareColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Equipment Requirement Chips
                if (caseItem.ambulanceCategory.isNotEmpty) ...[
                  Text(
                    'Ambulance: ${caseItem.ambulanceCategory}',
                    style: CustomerCareTextStyles.bodySm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    if (caseItem.oxygen) _buildChip('O2 Therapy'),
                    if (caseItem.icu) _buildChip('ICU Spec', isAlert: true),
                    if (caseItem.ventilator) _buildChip('Ventilator'),
                    if (caseItem.cardiacMonitor) _buildChip('Cardiac Monitor'),
                    if (caseItem.doctor) _buildChip('Physician Required'),
                    if (caseItem.emt) _buildChip('ACLS'),
                    if (caseItem.attendant) _buildChip('Medical Attendant'),
                    if (caseItem.stretcher) _buildChip('Stretcher'),
                    if (caseItem.wheelchair) _buildChip('Wheelchair'),
                  ],
                ),
                const SizedBox(height: 10),

                // Primary Start Call & Verify Action
                ElevatedButton.icon(
                  onPressed: onStartCallVerify,
                  icon: const Icon(Icons.phone_forwarded, size: 16),
                  label: Text(
                    caseItem.isDraft
                        ? 'OPEN DRAFT & CALL CUSTOMER'
                        : 'START CALL & VERIFY',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomerCareColors.primaryContainer,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(42),
                    textStyle: CustomerCareTextStyles.labelLg.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAlert
            ? CustomerCareColors.errorContainer
            : CustomerCareColors.surfaceContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: CustomerCareTextStyles.labelSm.copyWith(
          color: isAlert
              ? CustomerCareColors.onErrorContainer
              : CustomerCareColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 9.5,
        ),
      ),
    );
  }
}
