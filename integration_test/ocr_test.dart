import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:monologue/ocr/assemble_text.dart';
import 'package:monologue/ocr/text_recognizer.dart';
import 'package:path_provider/path_provider.dart';

import 'samples.dart';

/// 실제 기기(에뮬레이터·시뮬레이터)의 네이티브 인식기로 샘플 캡처를 읽는다.
/// 실행: `flutter test integration_test/ocr_test.dart -d <기기 ID>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('캡처 2장을 기기 인식기로 읽어 문단이 있는 본문 하나로 만든다', (tester) async {
    final dir = await (await getTemporaryDirectory()).createTemp('ocr_it');
    final paths = <String>[];
    for (final (i, b64) in [sample1Png, sample2Png].indexed) {
      final file = File('${dir.path}/sample$i.png');
      await file.writeAsBytes(base64Decode(b64));
      paths.add(file.path);
    }

    final ocr = PlatformTextRecognizer();
    final pages = [for (final p in paths) await ocr.recognize(p)];
    final text = assembleText(pages);
    // ignore: avoid_print
    print('--- OCR RESULT ---\n$text\n--- END ---');

    String squash(String s) => s.replaceAll(RegExp(r'\s'), '');
    for (final phrase in ['괜찮다고 말했어', '참 편리하더라', '하나도 괜찮지 않아', '또 웃고 있네']) {
      expect(squash(text), contains(squash(phrase)), reason: phrase);
    }
    // 캡처 맨 위 상태바(9:41 5G 87%)는 빠지고, 제목·문단들은 빈 줄로 나뉘어야 한다
    expect(text, isNot(contains('87%')));
    expect(text, isNot(contains('86%')));
    expect('\n\n'.allMatches(text).length, greaterThanOrEqualTo(3));
  });
}
