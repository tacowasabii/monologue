import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/data/script_repository.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/domain/script_notes.dart';
import 'package:monologue/ui/notes/notes_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('노트를 적고 저장하면 대본에 반영된다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final script = (await tester.runAsync(() async {
      final id = await h.services.repo.create(const ScriptDraft(work: '갈매기', body: 'x'));
      return (await h.services.repo.watchScript(id).first)!.script;
    }))!;
    await tester.pumpWidget(h.wrap(NotesScreen(script: script)));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, '상황'), '호숫가 무대, 공연 직후');
    await tester.enterText(find.widgetWithText(TextFormField, '원하는 것'), '인정받기');
    await tester.ensureVisible(find.text('연극'));
    await tester.tap(find.text('연극'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final saved = (await tester.runAsync(() => h.services.repo.watchScript(script.id).first))!.script.notes;
    expect(saved, const ScriptNotes(situation: '호숫가 무대, 공연 직후', objective: '인정받기', medium: ScriptMedium.play));
    await tester.runAsync(h.db.close);
  });

  testWidgets('저장하지 않고 나가려 하면 확인하고, 나가기를 누르면 바꾸지 않는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final script = (await tester.runAsync(() async {
      final id = await h.services.repo.create(const ScriptDraft(work: '갈매기', body: 'x'));
      return (await h.services.repo.watchScript(id).first)!.script;
    }))!;
    await tester.pumpWidget(h.wrap(Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NotesScreen(script: script))),
        child: const Text('열기'),
      ),
    )));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, '작가'), '체호프');
    // 입력 뒤 한 프레임을 그려야 PopScope가 바뀐 canPop(false)을 갖는다
    await tester.pump();
    // pageBack()은 영어 툴팁 'Back'을 찾으므로, 한국어 화면에서는 시스템 뒤로 가기를 직접 보낸다
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('저장하지 않고 나갈까요? 적은 내용은 사라져요.'), findsOneWidget);

    await tester.tap(find.text('나가기'));
    await tester.pumpAndSettle();
    expect(find.text('열기'), findsOneWidget);
    final saved = (await tester.runAsync(() => h.services.repo.watchScript(script.id).first))!.script.notes;
    expect(saved.isEmpty, isTrue);
    await tester.runAsync(h.db.close);
  });
}
