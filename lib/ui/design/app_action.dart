import 'package:flutter/material.dart';

import 'tokens.dart';

/// 버튼의 무게. 한 곳에 채운 버튼(primary·destructive)은 하나만 둔다.
enum AppActionKind {
  /// 가장 권하는 동작. 먹색·자주색으로 채운다
  primary,

  /// 지우기·버리기처럼 되돌릴 수 없는 동작. 경고색으로 채운다
  destructive,

  /// 취소나 다른 선택지. 외곽선만 둔다
  secondary,

  /// 세 개 이상 쌓을 때 맨 아래 취소처럼 가장 약한 동작. 글자만 둔다
  quiet,
}

/// 창·아래 막대에 놓는 버튼 하나. [onPressed]가 null이면 누를 수 없게 흐리게 보인다.
class AppAction {
  const AppAction(this.label, {required this.onPressed, this.kind = AppActionKind.primary, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final AppActionKind kind;
  final IconData? icon;
}

/// [AppAction]을 종류에 맞는 넓은 버튼으로 그린다.
class AppActionButton extends StatelessWidget {
  const AppActionButton(this.action, {super.key});

  final AppAction action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = Size.fromHeight(AppSize.actionButton);
    final child = switch (action.icon) {
      null => Text(action.label),
      final icon => Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon, size: 18), const SizedBox(width: AppSpace.sm), Flexible(child: Text(action.label))],
        ),
    };
    return switch (action.kind) {
      AppActionKind.primary => FilledButton(
          style: FilledButton.styleFrom(minimumSize: size),
          onPressed: action.onPressed,
          child: child,
        ),
      AppActionKind.destructive => FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: size,
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: action.onPressed,
          child: child,
        ),
      AppActionKind.secondary => OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: size),
          onPressed: action.onPressed,
          child: child,
        ),
      AppActionKind.quiet => TextButton(
          style: TextButton.styleFrom(minimumSize: size, foregroundColor: scheme.onSurfaceVariant),
          onPressed: action.onPressed,
          child: child,
        ),
    };
  }
}

/// 편집 모드처럼 고른 항목에 할 일을 화면 아래에 모아 두는 막대. 버튼은 같은 폭으로 나눠 갖는다.
class AppActionBar extends StatelessWidget {
  const AppActionBar({super.key, required this.actions});

  final List<AppAction> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.md, AppSpace.page, AppSpace.md),
          child: Row(
            children: [
              for (final (i, a) in actions.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: AppActionButton(a)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
