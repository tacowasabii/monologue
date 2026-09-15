import 'package:flutter/material.dart';

import 'tokens.dart';

/// 아래에서 올라오는 선택 시트를 띄운다. 위에 [AppSheetHeader], 그 아래 [children](보통 [AppSheetTile])을 둔다.
/// 항목을 누르면 `Navigator.pop(context, 값)`으로 고른 값을 돌려주고, 그냥 닫으면 null.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<Widget> Function(BuildContext context) children,
}) =>
    showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSheetHeader(title: title, subtitle: subtitle),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

/// 시트 맨 위 제목 줄. 설명 한 줄과 오른쪽 버튼(예: 초기화)을 붙일 수 있다.
/// 글자 크기·필터처럼 내용을 직접 그리는 시트도 이 제목 줄로 시작한다.
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                if (subtitle case final text?) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// 시트의 선택지 하나. 아이콘 상자, 이름, 설명을 둔 둥근 칸. [destructive]면 경고색으로 그리고 넘어가는 화살표를 뺀다.
class AppSheetTile extends StatelessWidget {
  const AppSheetTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: 2),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: destructive ? scheme.errorContainer : scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.small),
            ),
            child: Icon(icon, size: 20, color: destructive ? scheme.onErrorContainer : scheme.onPrimaryContainer),
          ),
          title: Text(title, style: destructive ? TextStyle(color: scheme.error) : null),
          subtitle: subtitle == null ? null : Text(subtitle!),
          trailing: destructive ? null : Icon(Icons.chevron_right_rounded, color: scheme.outline),
          onTap: onTap,
        ),
      ),
    );
  }
}
