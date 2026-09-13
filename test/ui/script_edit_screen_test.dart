import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_filter.dart';
import 'package:monologue/ui/edit/script_edit_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('본문이 비면 저장하지 않는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptEditScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('본문을 입력해 주세요'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('기본 정보는 작품명·메모이고 제목·인물 칸은 없다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptEditScreen()));
    await tester.pumpAndSettle();
    expect(find.text('제목'), findsNothing);
    expect(find.text('인물'), findsNothing);
    for (final label in ['작품명', '메모']) {
      expect(find.widgetWithText(TextFormField, label), findsOneWidget, reason: label);
    }
    await tester.runAsync(h.db.close);
  });

  testWidgets('메모를 적어 저장하면 대본과 함께 저장된다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptEditScreen(initialBody: '괜찮다는 말은\n참 편리하더라')));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '메모'), '2차 오디션 지정 대사');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    final list = await tester.runAsync(() => h.services.repo.watchScripts(const ScriptFilter()).first);
    expect(list!.single.script.memo, '2차 오디션 지정 대사');
    await tester.runAsync(h.db.close);
  });

  testWidgets('사진으로 만든 대본은 사진도 함께 저장된다고 알려 준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptEditScreen(initialBody: '본문', newImagePaths: ['a.png'])));
    await tester.pumpAndSettle();
    expect(find.text("사진 1장이 대본과 함께 보관돼요. 사진첩에서 캡처를 지워도 '원본 보기'로 다시 볼 수 있어요"), findsOneWidget);
    await tester.runAsync(h.db.close);
  });
}
