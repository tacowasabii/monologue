import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/ocr/text_recognizer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('monologue/ocr');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('네이티브가 준 줄 목록을 문단으로 묶어 돌려준다', () async {
    MethodCall? received;
    messenger.setMockMethodCallHandler(channel, (call) async {
      received = call;
      return [
        {'text': '그런데 오늘은', 'top': 200, 'left': 10, 'height': 20},
        {'text': '나는 늘 괜찮다고', 'top': 100, 'left': 10, 'height': 20},
        {'text': '말했어.', 'top': 130.0, 'left': 10.0, 'height': 20.0},
      ];
    });

    final blocks = await PlatformTextRecognizer().recognize('/tmp/a.png');

    expect(received?.method, 'recognize');
    expect(received?.arguments, {'path': '/tmp/a.png'});
    expect(blocks.map((b) => b.lines), [
      ['나는 늘 괜찮다고', '말했어.'],
      ['그런데 오늘은'],
    ]);
  });

  test('네이티브 오류는 그대로 올려 보낸다(캡처 화면이 사진 단위로 처리)', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'ocr_failed', message: 'bad image');
    });
    await expectLater(PlatformTextRecognizer().recognize('/tmp/a.png'), throwsA(isA<PlatformException>()));
  });
}
