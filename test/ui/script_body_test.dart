import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/theme.dart';
import 'package:monologue/ui/view/script_body.dart';

Widget host(Widget child) =>
    MaterialApp(theme: buildTheme(Brightness.light), home: Scaffold(body: SingleChildScrollView(child: child)));

Finder selectableOf(String text) => find.byWidgetPredicate((w) => w is SelectableText && w.data == keepWords(text));

void main() {
  testWidgets('독백은 본문을 한 덩어리로 보여준다', (tester) async {
    await tester.pumpWidget(host(const ScriptBody(body: '나는 늘 괜찮다고 말했어.', dialogue: false, fontSize: 20)));
    expect(selectableOf('나는 늘 괜찮다고 말했어.'), findsOneWidget);
  });

  testWidgets('대화는 인물 이름을 따로 보여주고 강조 인물이 아닌 대사는 흐리게 한다', (tester) async {
    await tester.pumpWidget(host(const ScriptBody(
      body: '민수: 왜 그랬어?\n지영: 몰라.\n(침묵)',
      dialogue: true,
      fontSize: 20,
      focusSpeaker: '지영',
    )));
    expect(find.text('민수'), findsOneWidget);
    expect(find.text('지영'), findsOneWidget);
    expect(find.text(keepWords('(침묵)')), findsOneWidget);
    double alphaOf(String text) => tester.widget<SelectableText>(selectableOf(text)).style!.color!.a;
    expect(alphaOf('몰라.'), 1.0);
    expect(alphaOf('왜 그랬어?'), lessThan(0.5));
  });

  testWidgets('selectable이 false면 고를 수 없는 글로 보여준다', (tester) async {
    await tester.pumpWidget(host(const ScriptBody(body: '민수: 가자', dialogue: true, fontSize: 20, selectable: false)));
    expect(find.byType(SelectableText), findsNothing);
    expect(find.text(keepWords('가자')), findsOneWidget);
  });
}
