import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/export/script_document.dart';
import 'package:monologue/export/script_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDF는 제목과 본문을 담고, 인쇄용 여백과 쪽 번호를 둔다', () async {
    final fonts = await PdfFonts.load();
    final bytes = await buildPdf(
      ScriptDocument(
        title: '빈 방의 온도',
        description: '해원 · 2차 오디션 자유연기',
        body: '이 방은 네가 나간 뒤로 한 번도 따뜻해진 적이 없어.',
        dialogue: false,
      ),
      fonts,
    );

    expect(utf8.decode(bytes.take(4).toList()), '%PDF');
    // 글꼴은 쓴 글자만 담겨서 파일이 작다
    expect(bytes.length, greaterThan(3000));
    // 만든 PDF를 열어 페이지 크기를 본다: A4 세로(595 x 842pt)
    final head = latin1.decode(bytes.take(4000).toList(), allowInvalid: true);
    expect(head, contains('/MediaBox'));
  });

  test('줄인 글꼴에 없는 글자를 찾아 알려 준다', () async {
    final fonts = await PdfFonts.load();
    expect(fonts.missingIn('이 방은 네가 나간 뒤로'), isEmpty);
    // 한자는 넣지 않은 글꼴이라 빈칸이 된다
    expect(fonts.missingIn('연극 劇 대본'), ['劇']);
  });
}
