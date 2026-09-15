import 'package:flutter/material.dart';

import 'tokens.dart';

// 칩은 세 가지다. 고른 것은 연한 자주 바탕 + 자주 글자, 고르지 않았거나 제안하는 것은 흰 바탕 + 옅은 테두리 + 회색 글자.
// 검은색·흰색으로 채우지 않는다. 규칙은 docs/design-system.md "칩".

TextStyle _labelStyle(ThemeData theme, Color color) => (theme.textTheme.labelLarge ?? const TextStyle())
    .copyWith(fontSize: 13.5, fontWeight: FontWeight.w600, letterSpacing: 0, color: color);

const _padding = EdgeInsets.symmetric(horizontal: 6);

/// 여러 개 중 고르는 칩(모음, 필터 선택지, 내 역할). 고르면 앞에 ✓가 붙어 색을 구분하기 어려워도 고른 게 보인다.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({super.key, required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    return FilterChip(
      label: Text(label),
      labelStyle: _labelStyle(theme, fg),
      selected: selected,
      showCheckmark: true,
      checkmarkColor: fg,
      color: WidgetStatePropertyAll(selected ? scheme.primaryContainer : scheme.surfaceContainerLowest),
      side: BorderSide(color: selected ? scheme.primary.withValues(alpha: 0.4) : scheme.outlineVariant),
      shape: const StadiumBorder(),
      padding: _padding,
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      onSelected: onSelected,
    );
  }
}

/// 붙인 태그나 목록 위에 걸어 둔 필터. ×를 누르면 [onDeleted], 칩을 누르면 [onPressed].
class AppTagChip extends StatelessWidget {
  const AppTagChip({super.key, required this.label, required this.onDeleted, this.onPressed, this.deleteTooltip});

  final String label;
  final VoidCallback onDeleted;
  final VoidCallback? onPressed;
  final String? deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = scheme.onPrimaryContainer;
    return InputChip(
      label: Text(label),
      labelStyle: _labelStyle(theme, fg),
      color: WidgetStatePropertyAll(scheme.primaryContainer),
      side: BorderSide(color: scheme.primary.withValues(alpha: 0.4)),
      shape: const StadiumBorder(),
      padding: _padding,
      // ×가 글자에서 멀리 떨어져 보이지 않게 오른쪽 여백을 없앤다
      labelPadding: const EdgeInsets.only(left: AppSpace.xs),
      deleteIcon: const Icon(Icons.close_rounded, size: 15),
      deleteIconColor: fg.withValues(alpha: 0.7),
      deleteButtonTooltipMessage: deleteTooltip ?? '$label 빼기',
      onDeleted: onDeleted,
      onPressed: onPressed,
    );
  }
}

/// 누르면 붙는 제안(만든 태그). 앞의 +로 고르기 칩과 구분한다.
class AppSuggestionChip extends StatelessWidget {
  const AppSuggestionChip({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = scheme.onSurfaceVariant;
    return ActionChip(
      avatar: Icon(Icons.add_rounded, size: 16, color: fg),
      label: Text(label),
      labelStyle: _labelStyle(theme, fg),
      color: WidgetStatePropertyAll(scheme.surfaceContainerLowest),
      side: BorderSide(color: scheme.outlineVariant),
      shape: const StadiumBorder(),
      padding: _padding,
      labelPadding: const EdgeInsets.only(left: 2, right: AppSpace.xs),
      onPressed: onPressed,
    );
  }
}
