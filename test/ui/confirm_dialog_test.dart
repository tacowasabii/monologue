import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/ui/common/confirm_dialog.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/theme.dart';

void main() {
  Future<List<bool>> pumpOpener(WidgetTester tester, {bool destructive = false}) async {
    final results = <bool>[];
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => results.add(await showConfirmDialog(
            context,
            title: '대본을 삭제할까요?',
            message: '원본 사진과 연습 기록도 함께 지워져요.',
            confirmLabel: '삭제',
            destructive: destructive,
          )),
          child: const Text('열기'),
        ),
      ),
    ));
    return results;
  }

  testWidgets('확인 창은 제목·설명과 넓은 두 버튼을 보여 주고, 누른 버튼이나 창 밖에 따라 결과를 돌려준다', (tester) async {
    final results = await pumpOpener(tester);

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('대본을 삭제할까요?'), findsOneWidget);
    expect(find.text(keepWords('원본 사진과 연습 기록도 함께 지워져요.')), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '취소'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '삭제'), findsOneWidget);
    // 두 버튼이 창 너비를 나눠 가진다
    expect(tester.getSize(find.byType(OutlinedButton)).width, tester.getSize(find.byType(FilledButton)).width);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // 창 밖
    await tester.pumpAndSettle();

    expect(results, [false, true, false]);
  });

  testWidgets('되돌릴 수 없는 동작이면 확인 버튼을 경고색으로 채운다', (tester) async {
    await pumpOpener(tester, destructive: true);
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final context = tester.element(find.byType(FilledButton));
    expect(button.style?.backgroundColor?.resolve({}), Theme.of(context).colorScheme.error);
  });
}
