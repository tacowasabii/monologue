import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/script_repository.dart';
import '../ui/design/design.dart';
import 'script_document.dart';
import 'script_pdf.dart';

enum ExportFormat {
  pdf('PDF', 'pdf', 'application/pdf'),
  docx('워드 문서', 'docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
  txt('텍스트', 'txt', 'text/plain');

  const ExportFormat(this.label, this.extension, this.mimeType);

  final String label;
  final String extension;
  final String mimeType;
}

/// 대본을 문서 파일로 만들어 공유 시트로 넘긴다. 거기서 인쇄하거나 파일로 저장한다.
/// 대본만 담는다(연기 노트·태그는 넣지 않는다). [anchor]는 iPad에서 공유 시트를 띄울 자리.
Future<void> exportScript(BuildContext context, ScriptDetail detail, {Rect? anchor}) async {
  final messenger = ScaffoldMessenger.of(context);
  void snack(String text) => messenger.showSnackBar(SnackBar(content: Text(text)));

  final format = await showAppSheet<ExportFormat>(
    context,
    title: '문서로 내보내기',
    subtitle: '대본만 담아요. 연기 노트와 태그는 빠져요',
    children: (context) => [
      AppSheetTile(
        icon: Icons.picture_as_pdf_outlined,
        title: 'PDF',
        subtitle: '인쇄에 좋아요 · 필기할 여백을 넓게 둬요',
        onTap: () => Navigator.pop(context, ExportFormat.pdf),
      ),
      AppSheetTile(
        icon: Icons.description_outlined,
        title: '워드 문서 (.docx)',
        subtitle: '워드·구글 문서·한글에서 고쳐 써요',
        onTap: () => Navigator.pop(context, ExportFormat.docx),
      ),
      AppSheetTile(
        icon: Icons.notes_rounded,
        title: '텍스트 (.txt)',
        subtitle: '어디서나 열려요',
        onTap: () => Navigator.pop(context, ExportFormat.txt),
      ),
    ],
  );
  if (format == null || !context.mounted) return;

  final doc = ScriptDocument.of(detail);
  final List<int> bytes;
  try {
    switch (format) {
      case ExportFormat.pdf:
        final fonts = await PdfFonts.load();
        // 줄인 글꼴이라 한자처럼 없는 글자는 PDF에서 빈칸이 된다. 만들기 전에 알려 준다
        final missing = fonts.missingIn('${doc.title}\n${doc.description ?? ''}\n${doc.body}');
        if (missing.isNotEmpty) {
          if (!context.mounted) return;
          final go = await showConfirmDialog(
            context,
            title: 'PDF에 담기 어려운 글자가 있어요',
            message: '${missing.take(8).join(' ')} 같은 글자는 PDF 글꼴에 없어서 빈칸으로 나와요. '
                '워드 문서나 텍스트로 내보내면 그대로 나와요.',
            confirmLabel: '그대로 만들기',
          );
          if (!go) return;
        }
        bytes = await buildPdf(doc, fonts);
      case ExportFormat.docx:
        bytes = buildDocx(doc);
      case ExportFormat.txt:
        bytes = buildTxt(doc);
    }
  } catch (_) {
    snack('문서를 만들지 못했어요. 다시 시도해 주세요.');
    return;
  }

  final String path;
  try {
    final dir = await getTemporaryDirectory();
    path = p.join(dir.path, '${doc.fileName}.${format.extension}');
    await File(path).writeAsBytes(Uint8List.fromList(bytes));
  } catch (_) {
    snack('문서를 저장하지 못했어요. 다시 시도해 주세요.');
    return;
  }

  try {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(path, mimeType: format.mimeType)],
      sharePositionOrigin: anchor,
    ));
  } catch (_) {
    snack('공유 화면을 열지 못했어요');
  }
}
