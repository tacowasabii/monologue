import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/ui/common/korean_text.dart';
import 'package:monologue/ui/settings/how_to_screen.dart';

void main() {
  testWidgets('사용 방법에 다섯 가지 안내가 모두 있다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HowToScreen()));
    await tester.pumpAndSettle();

    for (final title in ['사진으로 대본 만들기', '대본에 넣을 문단 고르기', '확인 필요 표시', '원본 사진 보관', '폰을 바꿀 때는 백업']) {
      await tester.scrollUntilVisible(find.text(title), 200);
      expect(find.text(title), findsOneWidget, reason: title);
    }
    // 사진첩을 비워도 된다는 핵심 내용이 들어 있어야 한다
    expect(find.textContaining(keepWords('사진첩에서 캡처를 지워도')), findsOneWidget);
  });
}
