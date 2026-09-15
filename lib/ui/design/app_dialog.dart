import 'package:flutter/material.dart';

import '../common/korean_text.dart';
import 'app_action.dart';
import 'tokens.dart';

/// 앱의 모든 가운데 창. 제목, 설명, 필요하면 입력칸 같은 [content], 아래에 넓은 버튼을 둔다.
/// 버튼이 둘까지면 가로로 나눠 갖고(왼쪽 취소, 오른쪽 권하는 동작), 셋 이상이거나 [stackActions]면 세로로 쌓는다(위가 권하는 동작).
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.actions = const [],
    this.stackActions = false,
  });

  final String title;
  final String? message;
  final Widget? content;
  final List<AppAction> actions;
  final bool stackActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stacked = stackActions || actions.length > 2;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: AppSpace.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSize.dialogMaxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, 26, AppSpace.xl, AppSpace.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              if (message case final text?) ...[
                const SizedBox(height: 10),
                Text(
                  keepWords(text),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.55, color: scheme.onSurfaceVariant),
                ),
              ],
              if (content case final body?) ...[
                SizedBox(height: message == null ? AppSpace.lg : AppSpace.md),
                body,
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpace.xl),
                if (stacked)
                  for (final (i, a) in actions.indexed) ...[
                    if (i > 0) const SizedBox(height: AppSpace.sm),
                    AppActionButton(a),
                  ]
                else
                  Row(
                    children: [
                      for (final (i, a) in actions.indexed) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: AppActionButton(a)),
                      ],
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 확인 창을 띄운다. 확인을 누르면 true, 취소를 누르거나 창 밖을 눌러 닫으면 false.
/// [destructive]면 확인 버튼을 경고색으로 채운다(지우기·버리기·나가기처럼 되돌릴 수 없는 동작).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String cancelLabel = '취소',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return ok ?? false;
}

/// 취소(외곽선)와 확인(채움) 두 버튼을 둔 [AppDialog].
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    this.message,
    required this.confirmLabel,
    this.cancelLabel = '취소',
    this.destructive = false,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) => AppDialog(
        title: title,
        message: message,
        actions: [
          AppAction(cancelLabel, kind: AppActionKind.secondary, onPressed: () => Navigator.pop(context, false)),
          AppAction(
            confirmLabel,
            kind: destructive ? AppActionKind.destructive : AppActionKind.primary,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );
}
