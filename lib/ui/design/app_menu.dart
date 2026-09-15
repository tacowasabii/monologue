import 'package:flutter/material.dart';

import 'tokens.dart';

/// 떠 있는 메뉴(대본 화면 ⋯, 목록 정렬)의 한 줄. 버튼 아래로 띄우는 `PopupMenuButton`의 항목으로 쓴다.
/// 고른 줄은 연한 자주 바탕 + 자주 글자 + 오른쪽 ✓, 되돌릴 수 없는 동작은 경고색이다.
PopupMenuItem<T> appMenuItem<T>(
  BuildContext context, {
  required T value,
  required String label,
  IconData? icon,
  bool selected = false,
  bool destructive = false,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final fg = destructive
      ? scheme.error
      : selected
          ? scheme.onPrimaryContainer
          : scheme.onSurface;
  return PopupMenuItem<T>(
    value: value,
    padding: EdgeInsets.zero,
    height: 44,
    child: Semantics(
      selected: selected,
      child: Container(
        width: double.infinity,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : null,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: destructive ? scheme.error : scheme.onSurfaceVariant),
              const SizedBox(width: AppSpace.md),
            ],
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 15,
                  color: fg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: AppSpace.md),
              Icon(Icons.check_rounded, size: 20, color: scheme.primary),
            ],
          ],
        ),
      ),
    ),
  );
}
