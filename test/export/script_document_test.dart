import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/export/script_document.dart';

void main() {
  ScriptDocument monologue() => ScriptDocument(
        title: '빈 방의 온도',
        description: '해원 · 2차 오디션 자유연기',
        body: '이 방은 네가 나간 뒤로 한 번도 따뜻해진 적이 없어.\n\n웃기지? 나 아직도 현관 불은 켜 둬.',
        dialogue: false,
      );

  ScriptDocument scene() => ScriptDocument(
        title: '새벽 세 시의 부엌',
        description: '수아 역 · 대화 장면 연습',
        body: '엄마: 이 시간에 뭐 하는 거야?\n수아: 물 마시러 나왔어.\n(사이)\n엄마: 캐리어는 왜 현관에 있어?',
        dialogue: true,
        myRole: '수아',
      );

  /// docx 안의 word/document.xml
  String documentXml(List<int> bytes) =>
      utf8.decode(ZipDecoder().decodeBytes(bytes).findFile('word/document.xml')!.readBytes()!);

  test('텍스트는 제목·설명·본문을 담고 BOM으로 시작한다', () {
    final bytes = buildTxt(monologue());
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final text = utf8.decode(bytes.sublist(3));
    expect(text, startsWith('빈 방의 온도\n해원 · 2차 오디션 자유연기\n\n'));
    expect(text, contains('이 방은 네가 나간 뒤로'));
    expect(text, contains('웃기지? 나 아직도'));
  });

  test('워드 문서는 열리는 구성을 갖추고 제목과 본문을 문단으로 담는다', () {
    final archive = ZipDecoder().decodeBytes(buildDocx(monologue()));
    expect(
      archive.files.map((f) => f.name).toSet(),
      containsAll(['[Content_Types].xml', '_rels/.rels', 'word/_rels/document.xml.rels', 'word/document.xml']),
    );
    final xml = documentXml(buildDocx(monologue()));
    expect(xml, contains('<w:t xml:space="preserve">빈 방의 온도</w:t>'));
    expect(xml, contains('이 방은 네가 나간 뒤로 한 번도 따뜻해진 적이 없어.'));
    // 인쇄한 종이에 적을 자리: 1.5줄 간격과 넓은 오른쪽 여백
    expect(xml, contains('w:line="360"'));
    expect(xml, contains('w:right="2551"'));
  });

  test('대화 대본은 인물 이름을 굵은 문단으로 먼저 둔다', () {
    final xml = documentXml(buildDocx(scene()));
    final speaker = xml.indexOf('<w:t xml:space="preserve">수아</w:t>');
    final line = xml.indexOf('<w:t xml:space="preserve">물 마시러 나왔어.</w:t>');
    expect(speaker, greaterThan(0));
    expect(speaker, lessThan(line));
    expect(xml.substring(0, speaker), contains('<w:b/>'));
    expect(xml, contains('(사이)'));
  });

  test('특수 문자는 문서가 깨지지 않게 바꿔 담는다', () {
    final xml = documentXml(buildDocx(ScriptDocument(title: 'A & B <극단>', body: "따옴표 \" 와 '", dialogue: false)));
    expect(xml, contains('A &amp; B &lt;극단&gt;'));
    expect(xml, contains('&quot;'));
    expect(xml, isNot(contains('<극단>')));
  });

  test('연기 노트와 태그는 담지 않는다', () {
    final doc = monologue();
    final text = utf8.decode(buildTxt(doc).sublist(3));
    expect(text, isNot(contains('#')));
    expect(text.split('\n').length, lessThan(8));
  });

  test('파일 이름은 쓸 수 없는 글자를 빼고 제목에서 만든다', () {
    expect(ScriptDocument(title: '햄릿/3막: 1장', body: 'x', dialogue: false).fileName, '햄릿 3막 1장');
    expect(ScriptDocument(title: '   ', body: 'x', dialogue: false).fileName, '대본');
  });
}
