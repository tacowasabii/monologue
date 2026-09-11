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

  testWidgets('인식된 본문으로 저장하면 제목이 첫 줄로 채워진다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptEditScreen(initialBody: '괜찮다는 말은\n참 편리하더라')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    final list = await tester.runAsync(() => h.services.repo.watchScripts(const ScriptFilter()).first);
    expect(list!.single.script.title, '괜찮다는 말은');
    await tester.runAsync(h.db.close);
  });
}
