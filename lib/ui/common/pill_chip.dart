import 'package:flutter/material.dart';

/// 선택되면 먹색으로 채워지는 둥근 칩. 목록 필터와 편집 화면의 선택지에 쓴다.
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.trailingIcon,
    this.onTrailing,
    this.trailingTooltip,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailing;
  final String? trailingTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.surface : scheme.onSurface;
    return FilterChip(
      avatar: icon == null ? null : Icon(icon, size: 16, color: selected ? fg : scheme.onSurfaceVariant),
      label: Text(label),
      labelStyle: (theme.chipTheme.labelStyle ?? const TextStyle()).copyWith(color: fg),
      selected: selected,
      showCheckmark: false,
      color: WidgetStatePropertyAll(selected ? scheme.onSurface : Colors.transparent),
      side: BorderSide(color: selected ? scheme.onSurface : scheme.outlineVariant),
      deleteIcon: trailingIcon == null ? null : Icon(trailingIcon, size: 16),
      deleteIconColor: selected ? fg : scheme.onSurfaceVariant,
      deleteButtonTooltipMessage: trailingTooltip,
      onDeleted: trailingIcon == null ? null : onTrailing,
      onSelected: onSelected,
    );
  }
}
