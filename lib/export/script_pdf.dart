import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'script_document.dart';

/// PDF에 담는 글꼴. 앱 화면의 명조 대신 문서에서 흔히 보는 고딕을 쓴다.
/// 한글 2,350자로 줄인 노토 산스 KR이라, 여기 없는 글자(한자 등)는 PDF에서 빠진다.
class PdfFonts {
  PdfFonts(this.regular, this.bold) : _glyphs = TtfParser(regular.data).charToGlyphIndexMap;

  final pw.TtfFont regular;
  final pw.TtfFont bold;

  /// 글꼴이 가진 글자(유니코드 → 글리프). 없는 글자를 미리 찾는 데 쓴다.
  final Map<int, int> _glyphs;

  static Future<PdfFonts> load([AssetBundle? bundle]) async {
    final assets = bundle ?? rootBundle;
    final regular = await assets.load('assets/fonts/NotoSansKR-Regular.ttf');
    final bold = await assets.load('assets/fonts/NotoSansKR-Bold.ttf');
    return PdfFonts(pw.TtfFont(regular), pw.TtfFont(bold));
  }

  /// 글꼴에 없어서 PDF에서 빈칸이 될 글자들(중복 없이, 나온 차례대로)
  List<String> missingIn(String text) {
    final out = <String>[];
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (ch.trim().isEmpty || _glyphs.containsKey(rune) || out.contains(ch)) continue;
      out.add(ch);
    }
    return out;
  }
}

/// 인쇄해서 필기하기 좋은 PDF. 줄 사이를 넓히고 오른쪽 여백을 크게 둔다.
Future<Uint8List> buildPdf(ScriptDocument d, PdfFonts fonts) async {
  final theme = pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold);
  final doc = pw.Document(theme: theme, title: d.title);
  const bodyStyle = pw.TextStyle(fontSize: 12, lineSpacing: 7);

  pw.Widget speech(String? speaker, String text, {required bool focused}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (speaker != null)
              pw.Text(
                speaker,
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: focused ? PdfColors.black : PdfColors.grey600,
                ),
              ),
            if (speaker != null) pw.SizedBox(height: 2),
            // 종이에서는 흐린 글씨가 읽기 어려워서 대사는 모두 진하게 두고, 인물 이름으로만 내 역할을 구분한다
            pw.Text(text, style: bodyStyle),
          ],
        ),
      );

  final content = <pw.Widget>[
    pw.Text(d.title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
    if (d.description case final text? when text.isNotEmpty) ...[
      pw.SizedBox(height: 4),
      pw.Text(text, style: const pw.TextStyle(fontSize: 10.5, color: PdfColors.grey700)),
    ],
    pw.SizedBox(height: 18),
    if (d.dialogue)
      for (final line in d.lines)
        if (line.direction)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Text(line.text, style: bodyStyle.copyWith(color: PdfColors.grey700, fontSize: 11)),
          )
        else
          speech(line.speaker, line.text, focused: d.myRole == null || d.myRole == line.speaker)
    else
      for (final paragraph in d.body.split('\n'))
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(paragraph, style: bodyStyle),
        ),
  ];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
        // 오른쪽을 넓게 비워 종이에 분석을 적을 자리를 둔다
        marginLeft: 2.2 * PdfPageFormat.cm,
        marginTop: 2.2 * PdfPageFormat.cm,
        marginRight: 4.5 * PdfPageFormat.cm,
        marginBottom: 2.2 * PdfPageFormat.cm,
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => content,
    ),
  );
  return doc.save();
}
