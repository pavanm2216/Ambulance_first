import 'package:flutter/material.dart';

import '../store/admin_store.dart';
import '../theme/admin_theme.dart';
import 'admin_shared.dart';

class AdminPricingScreen extends StatefulWidget {
  const AdminPricingScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<AdminPricingScreen> createState() => _AdminPricingScreenState();
}

class _AdminPricingScreenState extends State<AdminPricingScreen> {
  // Calculator inputs
  double _calcDistance = 25.0;
  String _calcCategory = 'ROAD';
  String _calcSubType = 'ICU';
  bool _calcDoc = true;
  bool _calcEmt = true;
  bool _calcVent = true;
  bool _calcIncubator = false;
  bool _calcNight = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final active = widget.store.activePricing;
        final draft = widget.store.draftPricing;

        final preview = widget.store.previewQuote(
          distanceKm: _calcDistance,
          serviceCategory: _calcCategory,
          subType: _calcSubType,
          needsDoctor: _calcDoc,
          needsEmt: _calcEmt,
          needsVentilator: _calcVent,
          needsIncubator: _calcIncubator,
          isNight: _calcNight,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(StitchTheme.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(StitchTheme.spaceMd),
                decoration: BoxDecoration(
                  color: StitchTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
                  border: Border.all(color: StitchTheme.borderSubtle),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: StitchTheme.primaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Pricing & Rate Card Engine',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: StitchTheme.headlineMd(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Versioned tariff matrix, medical fees, and preview calculator.',
                          style: StitchTheme.bodySm(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // Active Version Card
              Container(
                padding: const EdgeInsets.all(StitchTheme.spaceMd),
                decoration: BoxDecoration(
                  color: StitchTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
                  border: Border.all(color: StitchTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: StitchTheme.tertiaryFixed,
                            borderRadius: BorderRadius.circular(
                              StitchTheme.radiusSm,
                            ),
                          ),
                          child: Text(
                            'ACTIVE VERSION: ${active.versionId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StitchTheme.labelSm(
                              color: StitchTheme.onTertiaryFixed,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          'Effective: ${active.effectiveDate}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StitchTheme.labelSm(
                            color: StitchTheme.outline,
                          ),
                        ),
                        Text(
                          active.approvedBy,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: StitchTheme.labelSm(
                            color: StitchTheme.tertiary,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _rateRow(
                      'Road Basic Oxygen',
                      '${money(active.roadBasicOxygenBase)} Base + ${money(active.roadBasicOxygenPerKm)}/km',
                    ),
                    _rateRow(
                      'Road Mobile ICU',
                      '${money(active.roadIcuBase)} Base + ${money(active.roadIcuPerKm)}/km',
                    ),
                    _rateRow(
                      'Road Neonatal PICU',
                      '${money(active.roadPicuBase)} Base + ${money(active.roadPicuPerKm)}/km',
                    ),
                    _rateRow(
                      'Railway ICU Coach',
                      '${money(active.railwayBase)} Base',
                    ),
                    _rateRow(
                      'Air Medevac Jet',
                      '${money(active.airBaseRate)} Base + ${money(active.airPerKm)}/km',
                    ),
                    _rateRow(
                      'Mortuary Transfer',
                      '${money(active.deadBodyBase)} Base + ${money(active.deadBodyPerKm)}/km',
                    ),
                    const Divider(height: 12),
                    _rateRow('Attending Doctor Fee', money(active.doctorFee)),
                    _rateRow('Paramedic / EMT Fee', money(active.emtFee)),
                    _rateRow(
                      'Ventilator / Incubator',
                      '${money(active.ventilatorFee)} / ${money(active.incubatorFee)}',
                    ),
                    _rateRow(
                      'Night Surcharge / Tax',
                      '${active.nightSurchargePercent.round()}% Surcharge / ${active.taxPercent.round()}% Tax',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // Draft Version Banner & Activation
              Container(
                padding: const EdgeInsets.all(StitchTheme.spaceMd),
                decoration: BoxDecoration(
                  color: StitchTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
                  border: Border.all(color: StitchTheme.borderSubtle),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 10,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DATABASE CONFIGURATION: ${draft.versionId}',
                          style: StitchTheme.labelMd(weight: FontWeight.w700),
                        ),
                        Text(
                          'Source: ${draft.createdBy} · Updated ${draft.effectiveDate}',
                          style: StitchTheme.bodySm(),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final res = await widget.store
                            .activateDraftPricingFromDatabase();
                        if (!context.mounted) return;
                        showStitchToast(context, res.$2, isError: !res.$1);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: StitchTheme.primaryContainer,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save to Supabase'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StitchTheme.spaceLg),

              // Interactive Pricing Preview Calculator
              Container(
                padding: const EdgeInsets.all(StitchTheme.spaceMd),
                decoration: BoxDecoration(
                  color: StitchTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
                  border: Border.all(color: StitchTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.calculate_rounded,
                          size: 20,
                          color: StitchTheme.primaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Interactive Pricing Preview Calculator',
                            style: StitchTheme.headlineSm(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Estimated Transit Distance: ${_calcDistance.round()} km',
                          style: StitchTheme.labelMd(),
                        ),
                        SizedBox(
                          width: 180,
                          child: Slider(
                            value: _calcDistance,
                            min: 5,
                            max: 200,
                            divisions: 39,
                            activeColor: StitchTheme.primaryContainer,
                            onChanged: (v) => setState(() => _calcDistance = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _calcCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'ROAD',
                                child: Text('ROAD'),
                              ),
                              DropdownMenuItem(
                                value: 'AIR',
                                child: Text('AIR'),
                              ),
                              DropdownMenuItem(
                                value: 'RAILWAY',
                                child: Text('RAIL'),
                              ),
                              DropdownMenuItem(
                                value: 'DEAD_BODY',
                                child: Text('DEAD BODY'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _calcCategory = v ?? 'ROAD'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _calcSubType,
                            decoration: const InputDecoration(
                              labelText: 'Acuity Subtype',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'BASIC',
                                child: Text('Basic Oxygen'),
                              ),
                              DropdownMenuItem(
                                value: 'ICU',
                                child: Text('Mobile ICU'),
                              ),
                              DropdownMenuItem(
                                value: 'PICU',
                                child: Text('PICU'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _calcSubType = v ?? 'ICU'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Doctor'),
                          selected: _calcDoc,
                          onSelected: (v) => setState(() => _calcDoc = v),
                        ),
                        FilterChip(
                          label: const Text('EMT'),
                          selected: _calcEmt,
                          onSelected: (v) => setState(() => _calcEmt = v),
                        ),
                        FilterChip(
                          label: const Text('Ventilator'),
                          selected: _calcVent,
                          onSelected: (v) => setState(() => _calcVent = v),
                        ),
                        FilterChip(
                          label: const Text('Incubator'),
                          selected: _calcIncubator,
                          onSelected: (v) => setState(() => _calcIncubator = v),
                        ),
                        FilterChip(
                          label: const Text('Night Shift'),
                          selected: _calcNight,
                          onSelected: (v) => setState(() => _calcNight = v),
                        ),
                      ],
                    ),

                    const Divider(height: 16),

                    // Calculated Breakdown Output
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: StitchTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(
                          StitchTheme.radiusSm,
                        ),
                      ),
                      child: Column(
                        children: [
                          _rowCalc(
                            'Base Dispatch Fare',
                            money(preview['baseFare']),
                          ),
                          _rowCalc(
                            'Distance Transit Charge',
                            money(preview['distanceCharge']),
                          ),
                          _rowCalc(
                            'Clinical Staff Fee',
                            money(preview['doctorFee']! + preview['emtFee']!),
                          ),
                          _rowCalc(
                            'Equipment Surcharge',
                            money(preview['equipmentFees']),
                          ),
                          if (_calcNight)
                            _rowCalc(
                              'Night Protocol Surcharge (20%)',
                              money(preview['nightSurcharge']),
                            ),
                          _rowCalc('Applicable Taxes', money(preview['tax'])),
                          const Divider(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Simulated Total',
                                style: StitchTheme.headlineSm(),
                              ),
                              Text(
                                money(preview['total']),
                                style: StitchTheme.headlineMd(
                                  color: StitchTheme.primaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _rateRow(String title, String rates) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: StitchTheme.bodySm(color: StitchTheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              rates,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: StitchTheme.labelSm(weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowCalc(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: StitchTheme.bodySm(color: StitchTheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: StitchTheme.labelSm(weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
