import 'package:flutter/material.dart';
import '../models/admin_models.dart';
import '../theme/admin_theme.dart';

class StitchSafetySignoffDialog extends StatefulWidget {
  const StitchSafetySignoffDialog({
    super.key,
    required this.ambulance,
    required this.onConfirm,
  });

  final AdminAmbulance ambulance;
  final void Function(String pin, bool checklistPassed) onConfirm;

  @override
  State<StitchSafetySignoffDialog> createState() => _StitchSafetySignoffDialogState();
}

class _StitchSafetySignoffDialogState extends State<StitchSafetySignoffDialog> {
  bool _checkO2 = false;
  bool _checkDecon = false;
  bool _checkLeadCert = false;
  final TextEditingController _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_checkO2 || !_checkDecon || !_checkLeadCert) {
      setState(() {
        _error = 'All 3 clinical checklist verifications are mandatory before clearance.';
      });
      return;
    }
    if (_pinController.text.trim().length < 4) {
      setState(() {
        _error = 'Please enter a valid 4-digit Supervisor authorization PIN.';
      });
      return;
    }

    widget.onConfirm(_pinController.text.trim(), true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: StitchTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StitchTheme.radiusLg)),
      insetPadding: const EdgeInsets.all(StitchTheme.margin),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(StitchTheme.margin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog Header
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 22, color: StitchTheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Clinical Safety Sign-Off',
                  style: StitchTheme.headlineSm(color: StitchTheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Target Vehicle Strip
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: StitchTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TARGET VEHICLE',
                    style: StitchTheme.labelSm(color: StitchTheme.outline),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.ambulance.callSign} (${widget.ambulance.vehicleCadNo})',
                    style: StitchTheme.headlineSm(color: StitchTheme.primaryContainer),
                  ),
                  Text(
                    widget.ambulance.workOrder ?? '90-Day Medical Gas Calibration & Compressor',
                    style: StitchTheme.bodySm(color: StitchTheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Checklists
            CheckboxListTile(
              dense: true,
              value: _checkO2,
              contentPadding: EdgeInsets.zero,
              activeColor: StitchTheme.primaryContainer,
              title: Text(
                'Medical gases tested & sealed at full pressure',
                style: StitchTheme.bodySm(color: StitchTheme.onSurface),
              ),
              onChanged: (v) => setState(() => _checkO2 = v ?? false),
            ),
            CheckboxListTile(
              dense: true,
              value: _checkDecon,
              contentPadding: EdgeInsets.zero,
              activeColor: StitchTheme.primaryContainer,
              title: Text(
                'Decontamination completed and documented',
                style: StitchTheme.bodySm(color: StitchTheme.onSurface),
              ),
              onChanged: (v) => setState(() => _checkDecon = v ?? false),
            ),
            CheckboxListTile(
              dense: true,
              value: _checkLeadCert,
              contentPadding: EdgeInsets.zero,
              activeColor: StitchTheme.primaryContainer,
              title: Text(
                'Lead bio-engineer inspection certificate verified',
                style: StitchTheme.bodySm(color: StitchTheme.onSurface),
              ),
              onChanged: (v) => setState(() => _checkLeadCert = v ?? false),
            ),
            const SizedBox(height: 10),

            // PIN Field
            Text(
              'SAFETY LEAD STAFF ID PIN *',
              style: StitchTheme.labelSm(color: StitchTheme.outline, weight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: StitchTheme.labelMd(),
              decoration: InputDecoration(
                hintText: 'Enter 4-digit PIN',
                counterText: '',
                filled: true,
                fillColor: StitchTheme.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: StitchTheme.bodySm(color: StitchTheme.error),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Abort', style: StitchTheme.labelMd(color: StitchTheme.onSurfaceVariant)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StitchTheme.tertiary,
                    foregroundColor: StitchTheme.onTertiary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                    ),
                  ),
                  child: Text('Sign & Clear Ready', style: StitchTheme.labelMd(color: StitchTheme.onTertiary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
