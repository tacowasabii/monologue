import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/app.dart';
import 'package:monologue/app_scope.dart';
import 'package:monologue/settings/app_tips.dart';
import 'package:monologue/ui/home/home_screen.dart';
import 'package:monologue/ui/settings/how_to_screen.dart';
import 'package:monologue/ui/share/received_script_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('처음 켜면 사용 방법부터 보여 주고, 건너뛰면 대본 목록으로 가서 다시 켜도 보여 주지 않는다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(AppScope(services: h.services, child: const MonologueApp()));
    await tester.pumpAndSettle();
    expect(find.byType(HowToScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();
    expect(find.byType(HowToScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);

    final reopened = (await tester.runAsync(AppTips.load))!;
    expect(reopened.onboardingSeen, isTrue);
    await tester.runAsync(h.db.close);
  });

  testWidgets('공유 링크로 앱을 처음 켜도 받은 대본 화면이 사용 방법 위에 열린다', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(AppScope(services: h.services, child: const MonologueApp()));
    await tester.pumpAndSettle();

    h.links.open(Uri.parse('monologue://s/abcDEF1234abcDEF1234ab'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceivedScriptScreen), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(find.byType(HowToScreen), findsOneWidget);
    await tester.runAsync(h.db.close);
  });
}
