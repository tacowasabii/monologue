import 'package:flutter/material.dart';

import 'korean_text.dart';

/// 앱 전체에서 쓰는 확인 창을 띄운다. 확인을 누르면 true, 취소를 누르거나 창 밖을 눌러 닫으면 false.
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

/// 제목과 설명 아래에 넓은 버튼 두 개(취소는 외곽선, 확인은 채움)를 둔 확인 창.
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const buttonSize = Size.fromHeight(50);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: buttonSize),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(cancelLabel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: buttonSize,
                        backgroundColor: destructive ? scheme.error : null,
                        foregroundColor: destructive ? scheme.onError : null,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
