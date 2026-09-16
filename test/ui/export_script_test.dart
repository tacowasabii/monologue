import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/ui/view/script_view_screen.dart';

import 'test_harness.dart';

const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
const pathChannel = MethodChannel('plugins.flutter.io/path_provider');

/// 파일 쓰기가 끝나도록 실제 시간으로 기다렸다가 화면을 갱신한다.
Future<void> settleIo(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();
  }
}

void main() {
  late List<MethodCall> shareCalls;
  late Directory tmp;

  setUp(() {
    shareCalls = [];
    tmp = Directory.systemTemp.createTempSync('monologue_export');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      shareCalls.add(call);
      return 'dev.fluttercommunity.plus/share/success';
    });
    messenger.setMockMethodCallHandler(pathChannel, (call) async => tmp.path);
  });

  tearDown(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(shareChannel, null);
    messenger.setMockMethodCallHandler(pathChannel, null);
    tmp.deleteSync(recursive: true);
  });

  Future<Harness> openScript(WidgetTester tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    final id = (await tester.runAsync(() => h.services.repo.create(const ScriptDraft(
          work: '빈 방의 온도',
          memo: '해원 · 2차 오디션 자유연기',
          tags: ['상실'],
          note: '해원은 아직 기다린다',
          body: '이 방은 네가 나간 뒤로 한 번도 따뜻해진 적이 없어.',
        ))))!;
    await tester.pumpWidget(h.wrap(ScriptViewScreen(scriptId: id)));
    await tester.pumpAndSettle();
    return h;
  }

  testWidgets('본문 옆 복사 버튼은 본문 전체를 복사한다', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    final h = await openScript(tester);
    await tester.tap(find.byTooltip('본문 복사'));
    await tester.pumpAndSettle();

    expect(copied, '이 방은 네가 나간 뒤로 한 번도 따뜻해진 적이 없어.');
    expect(find.text('본문을 복사했어요'), findsOneWidget);
    await tester.runAsync(h.db.close);
  });

  testWidgets('내보내기는 양식을 고르게 하고, 고른 파일을 공유 시트로 넘긴다', (tester) async {
    final h = await openScript(tester);
    await tester.tap(find.byTooltip('문서로 내보내기'));
    await tester.pumpAndSettle();

    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('워드 문서 (.docx)'), findsOneWidget);
    expect(find.text('텍스트 (.txt)'), findsOneWidget);

    await tester.tap(find.text('텍스트 (.txt)'));
    await tester.pump();
    await settleIo(tester);

    final call = shareCalls.single;
    final paths = ((call.arguments as Map)['paths'] as List).cast<String>();
    expect(paths.single, endsWith('빈 방의 온도.txt'));
    final text = utf8.decode(File(paths.single).readAsBytesSync().sublist(3));
    expect(text, contains('빈 방의 온도'));
    expect(text, contains('이 방은 네가 나간 뒤로'));
    // 대본만 담는다
    expect(text, isNot(contains('해원은 아직 기다린다')));
    expect(text, isNot(contains('#상실')));
    await tester.runAsync(h.db.close);
  });
}
