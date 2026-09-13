import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/dialogue.dart';
import '../common/korean_text.dart';
import '../theme.dart';

/// 대본 본문. 대화 형식이면 인물 이름을 대사 위에 두고, [focusSpeaker]가 아닌 대사는 흐리게 한다.
/// 띄어쓰기에서만 줄이 바뀌도록 [keepWords]로 보여 주고, 복사할 때는 보이지 않는 문자를 뺀다.
class ScriptBody extends StatelessWidget {
  const ScriptBody({
    super.key,
    required this.body,
    required this.dialogue,
    required this.fontSize,
    this.focusSpeaker,
    this.selectable = true,
  });

  final String body;
  final bool dialogue;
  final double fontSize;
  final String? focusSpeaker;

  /// 몰입 읽기처럼 탭이 다른 일을 해야 하는 화면에서는 글자 선택을 끈다
  final bool selectable;

  static Widget _copyWithoutJoiners(BuildContext context, EditableTextState editable) =>
      AdaptiveTextSelectionToolbar.buttonItems(
        anchors: editable.contextMenuAnchors,
        buttonItems: [
          for (final item in editable.contextMenuButtonItems)
            if (item.type == ContextMenuButtonType.copy)
              item.copyWith(onPressed: () {
                final value = editable.textEditingValue;
                Clipboard.setData(ClipboardData(text: withoutWordJoiners(value.selection.textInside(value.text))));
                editable.hideToolbar();
              })
            else
              item,
        ],
      );

  Widget _text(String value, TextStyle style) => selectable
      ? SelectableText(keepWords(value), style: style, contextMenuBuilder: _copyWithoutJoiners)
      : Text(keepWords(value), style: style);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = TextStyle(fontFamily: serifFamily, fontSize: fontSize, height: 1.85, color: scheme.onSurface);
    if (!dialogue) return _text(body, base);

    Widget line(DialogueLine l) {
      if (l.direction) {
        return Text(keepWords(l.text), style: base.copyWith(fontSize: fontSize * 0.85, color: scheme.onSurfaceVariant));
      }
      final focused = focusSpeaker == l.speaker;
      final dim = focusSpeaker != null && !focused;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.speaker!,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: focused ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: dim ? 0.5 : 1),
            ),
          ),
          const SizedBox(height: 2),
          _text(l.text, base.copyWith(color: scheme.onSurface.withValues(alpha: dim ? 0.38 : 1))),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final l in parseDialogue(body))
          Padding(padding: EdgeInsets.only(bottom: fontSize * 0.9), child: line(l)),
      ],
    );
  }
}
