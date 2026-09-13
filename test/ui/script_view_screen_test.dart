import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_draft.dart';
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
}
