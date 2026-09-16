import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:monologue/app_scope.dart';
import 'package:monologue/backup/backup_service.dart';
import 'package:monologue/data/database.dart';
import 'package:monologue/data/image_store.dart';
import 'package:monologue/data/media_store.dart';
import 'package:monologue/data/script_repository.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/domain/script_filter.dart';
import 'package:monologue/export/script_document.dart';
import 'package:monologue/export/script_pdf.dart';
import 'package:monologue/ocr/text_recognizer.dart';
import 'package:monologue/platform/screen_awake.dart';
import 'package:monologue/practice/media_picker.dart';
import 'package:monologue/practice/voice_recorder.dart';
import 'package:monologue/settings/app_tips.dart';
import 'package:monologue/settings/home_view_settings.dart';
import 'package:monologue/settings/reading_settings.dart';
import 'package:monologue/share/link_source.dart';
import 'package:monologue/share/share_client.dart';
import 'package:monologue/share/share_history.dart';
import 'package:monologue/ui/theme.dart';
import 'package:monologue/ui/view/script_view_screen.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 실제 기기에서 문서 내보내기를 확인한다: 번들에 든 PDF 글꼴 읽기, 파일 만들기, 본문 복사, 양식 고르는 시트.
/// 공유 시트는 시스템 화면이라 열지 않는다(테스트가 멈춘다).
/// 실행: `flutter test integration_test/export_test.dart -d <기기 ID>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  setUp(() async => tmp = await (await getTemporaryDirectory()).createTemp('export_it'));
  tearDown(() => tmp.delete(recursive: true));

  const body = '엄마: 이 시간에 뭐 하는 거야?\n수아: 물 마시러 나왔어.\n(사이)\n수아: 엄마, 나 다음 주에 나가.';
  ScriptDocument sample() => ScriptDocument(
        title: '새벽 세 시의 부엌',
        description: '수아 역 · 대화 장면 연습',
        body: body,
        dialogue: true,
        myRole: '수아',
      );

  testWidgets('앱에 든 글꼴로 PDF를 만들고 기기 저장소에 쓴다', (tester) async {
    final fonts = await PdfFonts.load();
    expect(fonts.missingIn(body), isEmpty);
    expect(fonts.missingIn('한자 劇'), ['劇']);

    final bytes = await buildPdf(sample(), fonts);
    final file = File('${tmp.path}/${sample().fileName}.pdf');
    await file.writeAsBytes(bytes);

    expect(utf8.decode(bytes.take(4).toList()), '%PDF');
    expect(await file.length(), greaterThan(3000));
  });

  testWidgets('워드 문서와 텍스트도 기기에서 만들어진다', (tester) async {
    final docx = File('${tmp.path}/${sample().fileName}.docx');
    await docx.writeAsBytes(buildDocx(sample()));
    final entry = ZipDecoder().decodeBytes(await docx.readAsBytes()).findFile('word/document.xml');
    expect(utf8.decode(entry!.readBytes()!), contains('새벽 세 시의 부엌'));

    final txt = File('${tmp.path}/${sample().fileName}.txt');
    await txt.writeAsBytes(buildTxt(sample()));
    final text = utf8.decode((await txt.readAsBytes()).sublist(3));
    expect(text, startsWith('새벽 세 시의 부엌'));
    expect(text, contains('물 마시러 나왔어.'));
  });

  testWidgets('대본 화면에서 본문을 복사하고, 내보내기 시트에서 양식을 고를 수 있다', (tester) async {
    final db = AppDatabase(NativeDatabase(File('${tmp.path}/export.sqlite')));
    final images = ImageStore(await Directory('${tmp.path}/images').create());
    final media = MediaStore(await Directory('${tmp.path}/media').create());
    final repo = ScriptRepository(db, images, media);
    final id = await repo.create(const ScriptDraft(
      work: '새벽 세 시의 부엌',
      memo: '수아 역 · 대화 장면 연습',
      dialogue: true,
      myRole: '수아',
      body: body,
    ));
    expect((await repo.watchScripts(const ScriptFilter()).first).single.script.id, id);

    await tester.pumpWidget(AppScope(
      services: AppServices(
        repo: repo,
        images: images,
        media: media,
        ocr: PlatformTextRecognizer(),
        backup: BackupService(db, repo, images),
        settings: await ReadingSettings.load(),
        tips: await AppTips.load(),
        homeView: await HomeViewSettings.load(),
        newRecorder: RecordVoiceRecorder.new,
        mediaPicker: PlatformMediaPicker(),
        screen: PlatformScreenAwake(),
        shareClient: ShareClient(http.Client()),
        shareHistory: await ShareHistory.load(),
        links: PlatformLinkSource(),
      ),
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: ScriptViewScreen(scriptId: id),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('본문 복사'));
    await tester.pumpAndSettle();
    expect((await Clipboard.getData(Clipboard.kTextPlain))?.text, body);
    expect(find.text('본문을 복사했어요'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('문서로 내보내기'));
    await tester.pumpAndSettle();
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('워드 문서 (.docx)'), findsOneWidget);
    expect(find.text('텍스트 (.txt)'), findsOneWidget);
    // 양식을 고르면 시스템 공유 화면이 떠서 여기서는 시트만 닫는다
    await tester.tapAt(const Offset(20, 60));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
