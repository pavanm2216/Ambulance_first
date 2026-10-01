import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

class StitchBottomNav extends StatelessWidget {
  const StitchBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpenMore,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StitchTheme.surface.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: StitchTheme.borderSubtle, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -2),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(child: _NavItem(icon: Icons.grid_view_rounded, label: 'Cmd', isSelected: selectedIndex == 0, onTap: () => onSelect(0))),
              Expanded(child: _NavItem(icon: Icons.near_me_rounded, label: 'Dispatch', isSelected: selectedIndex == 1, onTap: () => onSelect(1))),
              Expanded(child: _NavItem(icon: Icons.local_shipping_rounded, label: 'Fleet', isSelected: selectedIndex == 2, onTap: () => onSelect(2))),
              Expanded(child: _NavItem(icon: Icons.groups_rounded, label: 'Staff', isSelected: selectedIndex == 3, onTap: () => onSelect(3))),
              Expanded(child: _NavItem(icon: Icons.receipt_long_rounded, label: 'Finance', isSelected: selectedIndex == 4, onTap: () => onSelect(4))),
              Expanded(child: _NavItem(icon: Icons.menu_rounded, label: 'More', isSelected: false, onTap: onOpenMore)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = StitchTheme.primaryContainer;
    final inactiveColor = StitchTheme.onSurfaceVariant;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? StitchTheme.surfaceContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(StitchTheme.radiusSm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isSelected ? activeColor : inactiveColor),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: StitchTheme.labelSm(
                  color: isSelected ? activeColor : inactiveColor,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
