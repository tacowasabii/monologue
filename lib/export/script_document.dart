import 'dart:convert';

import 'package:archive/archive.dart';

import '../data/script_repository.dart';
import '../domain/dialogue.dart';

/// 문서로 내보낼 대본 한 편. 인쇄하거나 옮겨 적기 좋게 대본만 담는다(연기 노트·태그는 담지 않는다).
class ScriptDocument {
  ScriptDocument({required this.title, this.description, required this.body, required this.dialogue, this.myRole});

  /// 대본 화면의 한 편에서 만든다. 작품명이 없으면 본문 첫 줄을 제목으로 쓴다.
  factory ScriptDocument.of(ScriptDetail detail) {
    final s = detail.script;
    final firstLine = s.body.trim().split('\n').first.trim();
    return ScriptDocument(
      title: (s.work?.trim().isNotEmpty ?? false) ? s.work!.trim() : firstLine,
      description: s.memo?.trim().split('\n').first.trim(),
      body: s.body.trim(),
      dialogue: s.dialogue,
      myRole: s.myRole,
    );
  }

  final String title;

  /// 한 줄 설명
  final String? description;
  final String body;
  final bool dialogue;

  /// 대화 대본에서 진하게 보여 줄 인물
  final String? myRole;

  List<DialogueLine> get lines => parseDialogue(body);

  /// 파일 이름에 쓸 수 없는 글자를 뺀 제목. 비면 '대본'.
  String get fileName {
    final clean = title.replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), ' ').trim().replaceAll(RegExp(r'\s+'), ' ');
    final short = clean.length > 40 ? clean.substring(0, 40).trim() : clean;
    return short.isEmpty ? '대본' : short;
  }
}

/// 텍스트 파일 내용. 윈도우 메모장에서도 한글이 깨지지 않게 BOM을 앞에 둔다.
List<int> buildTxt(ScriptDocument d) {
  final buffer = StringBuffer()..writeln(d.title);
  if (d.description case final text? when text.isNotEmpty) buffer.writeln(text);
  buffer
    ..writeln()
    ..write(d.body);
  return [0xEF, 0xBB, 0xBF, ...utf8.encode(buffer.toString())];
}

/// 워드 문서(.docx). 최소 구성의 OOXML을 압축해서 만든다.
/// 글꼴을 담지 않아서 워드·한글·구글 문서가 각자 기본 글꼴로 연다.
List<int> buildDocx(ScriptDocument d) {
  final body = StringBuffer()
    ..write(_p(d.title, bold: true, sizeHalfPoints: 32, spaceAfter: 120));
  if (d.description case final text? when text.isNotEmpty) {
    body.write(_p(text, italic: true, sizeHalfPoints: 20, spaceAfter: 360));
  }
  if (d.dialogue) {
    for (final line in d.lines) {
      if (line.direction) {
        body.write(_p(line.text, italic: true, spaceAfter: 200));
        continue;
      }
      body
        ..write(_p(line.speaker ?? '', bold: true, sizeHalfPoints: 20, spaceAfter: 0))
        ..write(_p(line.text, spaceAfter: 240));
    }
  } else {
    for (final paragraph in d.body.split('\n')) {
      body.write(_p(paragraph, spaceAfter: 200));
    }
  }
  // 오른쪽을 넓게 비워 인쇄한 종이에 필기할 자리를 둔다(twip: 1440 = 1인치)
  body.write('<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
      '<w:pgMar w:top="1417" w:right="2551" w:bottom="1417" w:left="1417" w:header="709" w:footer="709"/></w:sectPr>');

  final archive = Archive()
    ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypes))
    ..addFile(ArchiveFile.string('_rels/.rels', _rels))
    ..addFile(ArchiveFile.string('word/_rels/document.xml.rels', _documentRels))
    ..addFile(ArchiveFile.string(
      'word/document.xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:body>$body</w:body></w:document>',
    ));
  return ZipEncoder().encodeBytes(archive);
}

/// 한 문단. 줄 간격은 1.5줄(line 360, auto)로 둬서 줄 사이에 적을 자리를 남긴다.
String _p(
  String text, {
  bool bold = false,
  bool italic = false,
  int sizeHalfPoints = 22,
  int spaceAfter = 200,
}) {
  final runProperties = StringBuffer('<w:rPr>')
    ..write(bold ? '<w:b/>' : '')
    ..write(italic ? '<w:i/>' : '')
    ..write('<w:sz w:val="$sizeHalfPoints"/><w:szCs w:val="$sizeHalfPoints"/></w:rPr>');
  final runs = <String>[];
  for (final (i, line) in text.split('\n').indexed) {
    if (i > 0) runs.add('<w:r>$runProperties<w:br/></w:r>');
    runs.add('<w:r>$runProperties<w:t xml:space="preserve">${_escape(line)}</w:t></w:r>');
  }
  return '<w:p><w:pPr><w:spacing w:line="360" w:lineRule="auto" w:after="$spaceAfter"/></w:pPr>${runs.join()}</w:p>';
}

String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

const _contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/word/document.xml" '
    'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
    '</Types>';

const _rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" '
    'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
    '</Relationships>';

const _documentRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"></Relationships>';
