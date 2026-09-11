import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/list/script_list_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('대본이 없으면 안내 문구를 보여준다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(h.wrap(const ScriptListScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 대본이 없어요'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('검색어로 목록을 거른다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.runAsync(() async {
      await h.services.repo.create(const ScriptDraft(title: '햄릿', body: '사느냐 죽느냐'));
      await h.services.repo.create(const ScriptDraft(title: '갈매기', body: '나는 갈매기', gender: Gender.female));
    });
    await tester.pumpWidget(h.wrap(const ScriptListScreen()));
    await tester.pumpAndSettle();
    expect(find.text('햄릿'), findsOneWidget);
    expect(find.text('갈매기'), findsOneWidget);

    await tester.enterText(find.byType(SearchBar), '죽느냐');
    await tester.pumpAndSettle();
    expect(find.text('햄릿'), findsOneWidget);
    expect(find.text('갈매기'), findsNothing);
    await tester.runAsync(h.db.close);
  });
}
