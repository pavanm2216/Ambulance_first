import 'package:flutter/material.dart';

import '../models/admin_models.dart';
import '../store/admin_store.dart';
import '../theme/admin_theme.dart';
import 'admin_shared.dart';

class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key, required this.store});

  final AdminStore store;

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedSeverity = 'ALL';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final logs = widget.store.auditLogs;
        final q = _searchCtrl.text.trim().toLowerCase();

        final filtered = logs.where((e) {
          if (q.isNotEmpty) {
            final text =
                '${e.id} ${e.action} ${e.actor} ${e.role} ${e.entity} ${e.entityId} ${e.details}'
                    .toLowerCase();
            if (!text.contains(q)) return false;
          }
          if (_selectedSeverity != 'ALL' && e.severity != _selectedSeverity) {
            return false;
          }
          return true;
        }).toList();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 20,
                          color: StitchTheme.primaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Audit Trail & Governance',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StitchTheme.headlineMd(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Administrative event history loaded from the Supabase audit ledger.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: StitchTheme.bodySm(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton.outlined(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        onPressed: () async {
                          await widget.store.refresh();
                          if (!context.mounted) return;
                          showStitchToast(
                            context,
                            widget.store.errorMessage == null
                                ? 'Audit data refreshed from Supabase.'
                                : 'Audit refresh failed.',
                            isError: widget.store.errorMessage != null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // Search Input
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by action, actor, entity ID, or details...',
                  hintStyle: StitchTheme.bodySm(color: StitchTheme.outline),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          onPressed: () => setState(() => _searchCtrl.clear()),
                        )
                      : null,
                  filled: true,
                  fillColor: StitchTheme.surfaceContainerLowest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Severity Filter Chips
              Row(
                children: [
                  _SeverityChip(
                    label: 'All (${logs.length})',
                    isSelected: _selectedSeverity == 'ALL',
                    onTap: () => setState(() => _selectedSeverity = 'ALL'),
                  ),
                  const SizedBox(width: 6),
                  _SeverityChip(
                    label: 'Info',
                    isSelected: _selectedSeverity == 'INFO',
                    onTap: () => setState(() => _selectedSeverity = 'INFO'),
                  ),
                  const SizedBox(width: 6),
                  _SeverityChip(
                    label: 'Warning',
                    isSelected: _selectedSeverity == 'WARNING',
                    onTap: () => setState(() => _selectedSeverity = 'WARNING'),
                  ),
                  const SizedBox(width: 6),
                  _SeverityChip(
                    label: 'Critical',
                    isSelected: _selectedSeverity == 'CRITICAL',
                    onTap: () => setState(() => _selectedSeverity = 'CRITICAL'),
                  ),
                ],
              ),
              const SizedBox(height: StitchTheme.spaceMd),

              // Audit Cards List
              for (final entry in filtered) ...[
                _AuditCard(
                  entry: entry,
                  onTap: () => _openDiffDialog(context, entry),
                ),
                const SizedBox(height: StitchTheme.spaceSm),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _openDiffDialog(BuildContext context, AdminAuditEntry e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StitchTheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.difference_rounded,
              size: 20,
              color: StitchTheme.primaryContainer,
            ),
            const SizedBox(width: 8),
            Text('Audit Event — ${e.id}', style: StitchTheme.headlineSm()),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _diffMeta('Timestamp', e.timestamp.toIso8601String()),
              _diffMeta('Actor', '${e.actor} (${e.role})'),
              _diffMeta('Action', e.action),
              _diffMeta('Target Entity', '${e.entity} [${e.entityId}]'),
              _diffMeta('Severity', e.severity),
              const Divider(height: 16),
              Text(
                'EVENT DETAILS',
                style: StitchTheme.labelSm(
                  color: StitchTheme.outline,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(e.details, style: StitchTheme.bodyMd()),
              const Divider(height: 16),
              Text(
                'STATE MUTATION DIFF',
                style: StitchTheme.labelSm(
                  color: StitchTheme.outline,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StitchTheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREVIOUS STATE (-)',
                      style: StitchTheme.labelSm(
                        color: StitchTheme.error,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.previousValue.isNotEmpty
                          ? e.previousValue
                          : 'None / Unset',
                      style: StitchTheme.bodySm(
                        color: StitchTheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StitchTheme.tertiaryFixed.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEW STATE (+)',
                      style: StitchTheme.labelSm(
                        color: StitchTheme.tertiary,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.newValue.isNotEmpty ? e.newValue : 'None / Deleted',
                      style: StitchTheme.bodySm(
                        color: StitchTheme.onTertiaryFixed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _diffMeta(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 2,
        children: [
          Text(label, style: StitchTheme.bodySm(color: StitchTheme.outline)),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              val,
              textAlign: TextAlign.right,
              style: StitchTheme.labelSm(
                color: StitchTheme.onSurface,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? StitchTheme.primaryContainer
              : StitchTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
          border: Border.all(
            color: isSelected
                ? StitchTheme.primaryContainer
                : StitchTheme.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: StitchTheme.labelSm(
            color: isSelected ? Colors.white : StitchTheme.onSurface,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.entry, required this.onTap});
  final AdminAuditEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final color = e.severity == 'CRITICAL'
        ? StitchTheme.error
        : e.severity == 'WARNING'
        ? StitchTheme.warning
        : StitchTheme.tertiary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(StitchTheme.radiusLg),
      child: Container(
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
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${e.action} [${e.entityId}]',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: StitchTheme.labelMd(weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateTime.now().difference(e.timestamp).inMinutes}m ago',
                  style: StitchTheme.labelSm(color: StitchTheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              e.details,
              style: StitchTheme.bodySm(color: StitchTheme.onSurface),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 4,
              children: [
                Text(
                  'By: ${e.actor} (${e.role})',
                  style: StitchTheme.bodySm(color: StitchTheme.outline),
                ),
                Row(
                  children: [
                    Text(
                      'Inspect Diff',
                      style: StitchTheme.labelSm(
                        color: StitchTheme.primaryContainer,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: StitchTheme.primaryContainer,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
