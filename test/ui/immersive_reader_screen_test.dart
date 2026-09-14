import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/view/immersive_reader_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('몰입 읽기는 대본만 보여 주고, 화면 꺼짐을 막고, 닫으면 풀고, 탭하면 메뉴가 나온다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final script = (await tester.runAsync(() async {
      final id = await h.services.repo.create(const ScriptDraft(
        work: '독백',
        body: '괜찮다는 말은 참 편리하더라.',
        note: '새벽 세 시, 부엌',
      ));
      return (await h.services.repo.watchScript(id).first)!.script;
    }))!;
    await tester.pumpWidget(h.wrap(ImmersiveReaderScreen(script: script)));
    await tester.pumpAndSettle();

    expect(h.screen.calls, [true]);
    // 노트는 대본 화면에서 보고, 몰입 읽기에서는 대본에만 집중한다
    expect(find.text(keepWords('새벽 세 시, 부엌')), findsNothing);
    expect(find.byTooltip('몰입 읽기 닫기').hitTestable(), findsNothing);

    await tester.tap(find.text(keepWords('괜찮다는 말은 참 편리하더라.')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('몰입 읽기 닫기').hitTestable(), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(h.screen.calls, [true, false]);
    await tester.runAsync(h.db.close);
  });
}
