import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/view/script_view_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('대본 본문을 복사하면 줄바꿈용 보이지 않는 문자 없이 원문 그대로 복사된다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    const body = '나는 늘 괜찮다고 말했어. 아침에 눈을 뜰 때도, 버스에서 창밖을 볼 때도.';
    final id = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(body: body))))!;

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: id)));
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(SelectableText));
    await tester.pumpAndSettle();
    await tester.tap(find.text('전체 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('복사'));
    await tester.pumpAndSettle();

    expect(copied, body);
    await tester.runAsync(h.db.close);
  });

  testWidgets('대화 대본은 저장된 내 역할을 강조하고, 칩을 누르면 역할이 바뀌어 저장된다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final id = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(
          work: '장면',
          body: '민수: 왜 그랬어?\n지영: 몰라.',
          dialogue: true,
          myRole: '지영',
        ))))!;
    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: id)));
    await tester.pumpAndSettle();

    double alphaOf(String text) => tester
        .widget<SelectableText>(find.byWidgetPredicate((w) => w is SelectableText && w.data == keepWords(text)))
        .style!
        .color!
        .a;
    expect(alphaOf('왜 그랬어?'), lessThan(0.5));

    await tester.tap(find.widgetWithText(FilterChip, '민수'));
    await tester.pumpAndSettle();
    expect(alphaOf('왜 그랬어?'), 1.0);
    expect(alphaOf('몰라.'), lessThan(0.5));
    final saved = await tester.runAsync(() => h.services.repo.watchScript(id).first);
    expect(saved!.script.myRole, '민수');
    await tester.runAsync(h.db.close);
  });
}
