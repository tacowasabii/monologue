import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../domain/dialogue.dart';
import '../common/korean_text.dart';
import '../theme.dart';
import '../view/script_body.dart';

/// 편집 화면에서 '대화'를 고르면 본문 위에 보여 주는 적는 법 예시.
/// 독백과 입력 칸이 같아서 처음에는 어떻게 적어야 인물별로 나뉘는지 알기 어렵다.
class DialogueExample extends StatelessWidget {
  const DialogueExample({super.key});

  static const lines = ['(늦은 밤, 편의점 앞)', '민수: 왜 연락 안 했어?', '지영: 바빴어.'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이렇게 적어요', style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final line in lines)
            Text(
              line,
              style: TextStyle(
                fontFamily: serifFamily,
                fontSize: 15,
                height: 1.6,
                color: line.startsWith('(') ? scheme.onSurfaceVariant : scheme.onSurface,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            keepWords('줄 앞에 이름과 콜론(:)을 쓰면 그 인물의 대사, 괄호로만 된 줄은 지문이에요. 이름 없는 줄은 윗줄 대사에 이어져요.'),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// 본문 아래에서 적은 내용이 인물·대사·지문으로 어떻게 나뉘었는지 바로 알려 주고, 나뉜 모습을 미리 보여 준다.
class DialogueCheck extends StatelessWidget {
  const DialogueCheck({super.key, required this.body});

  final String body;

  void _preview(BuildContext context) {
    final fontSize = AppScope.of(context).settings.fontSize;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Text('대본 화면에서 이렇게 보여요', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            ScriptBody(body: body, dialogue: true, fontSize: fontSize, selectable: false),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = summarizeDialogue(body);
    if (s.speakers.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: scheme.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              keepWords("아직 인물 대사가 없어요. '민수: 대사'처럼 이름과 콜론으로 적어 주세요."),
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error, height: 1.5),
            ),
          ),
        ],
      );
    }
    // 인물이 많으면 앞의 몇 명만 이름을 보여 준다
    final names = s.speakers.length > 4 ? '${s.speakers.take(4).join(', ')} 외' : s.speakers.join(', ');
    return Row(
      children: [
        Icon(Icons.check_circle_outline_rounded, size: 18, color: scheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '인물 ${s.speakers.length}명($names) · 대사 ${s.speeches} · 지문 ${s.directions}',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        TextButton(onPressed: () => _preview(context), child: const Text('미리보기')),
      ],
    );
  }
}
