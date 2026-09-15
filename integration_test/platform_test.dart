import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:monologue/app.dart';
import 'package:monologue/app_scope.dart';
import 'package:monologue/backup/backup_service.dart';
import 'package:monologue/data/database.dart';
import 'package:monologue/data/image_store.dart';
import 'package:monologue/data/media_store.dart';
import 'package:monologue/data/script_repository.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/domain/script_draft.dart';
import 'package:monologue/domain/script_filter.dart';
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
import 'package:monologue/ui/common/adaptive.dart';
import 'package:monologue/ui/home/home_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:video_player/video_player.dart';

import 'media_samples.dart';

/// 노트가 여러 칸이던 DB 버전 7의 표
const _v7Schema = [
  'CREATE TABLE "scripts" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "work" TEXT NULL, "memo" TEXT NULL, '
      '"gender" TEXT NOT NULL, "age_range" TEXT NOT NULL, "status" TEXT NOT NULL, '
      '"favorite" INTEGER NOT NULL CHECK ("favorite" IN (0, 1)), "body" TEXT NOT NULL, '
      '"created_at" TEXT NOT NULL, "updated_at" TEXT NOT NULL, '
      '"dialogue" INTEGER NOT NULL DEFAULT 0 CHECK ("dialogue" IN (0, 1)), "my_role" TEXT NULL, '
      '"situation" TEXT NULL, "objective" TEXT NULL, "obstacle" TEXT NULL, "author" TEXT NULL, "medium" TEXT NULL, '
      '"source_url" TEXT NULL, "synopsis" TEXT NULL, "scene_context" TEXT NULL);',
  'CREATE TABLE "script_tags" ("script_id" INTEGER NOT NULL REFERENCES scripts (id), "tag" TEXT NOT NULL, '
      'PRIMARY KEY ("script_id", "tag"));',
  'CREATE TABLE "script_images" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"script_id" INTEGER NOT NULL REFERENCES scripts (id), "file_name" TEXT NOT NULL, "position" INTEGER NOT NULL);',
  'CREATE TABLE "collections" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "name" TEXT NOT NULL UNIQUE, '
      '"created_at" TEXT NOT NULL);',
  'CREATE TABLE "script_collections" ("script_id" INTEGER NOT NULL REFERENCES scripts (id), '
      '"collection_id" INTEGER NOT NULL REFERENCES collections (id), "position" INTEGER NOT NULL DEFAULT 0, '
      'PRIMARY KEY ("script_id", "collection_id"));',
  'CREATE TABLE "script_media" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"script_id" INTEGER NOT NULL REFERENCES scripts (id), "kind" TEXT NOT NULL, "file_name" TEXT NOT NULL, '
      '"duration_ms" INTEGER NULL, "created_at" TEXT NOT NULL);',
];

/// 실제 기기(시뮬레이터·에뮬레이터)의 네이티브 플러그인으로 DB 올리기, 녹음·재생, 영상 읽기, 백업, 주요 화면을 확인한다.
/// 사진첩·파일 고르기와 카메라 촬영은 시스템 화면이라 여기서 다루지 않는다.
/// 실행: `flutter test integration_test/platform_test.dart -d <기기 ID>`
/// 마이크 권한을 미리 허용해 둔다(iOS 시뮬레이터: `xcrun simctl privacy <기기 ID> grant microphone com.tacowasabii.monologue`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // 백업 확인에서 두 기기를 흉내 내려고 DB를 일부러 둘 연다
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  setUp(() async => tmp = await (await getTemporaryDirectory()).createTemp('platform_it'));
  tearDown(() => tmp.delete(recursive: true));

  Future<(AppDatabase, ScriptRepository, ImageStore, MediaStore)> openStore(String name) async {
    final db = AppDatabase(NativeDatabase(File('${tmp.path}/$name.sqlite')));
    final images = ImageStore(await Directory('${tmp.path}/$name-images').create());
    final media = MediaStore(await Directory('${tmp.path}/$name-media').create());
    return (db, ScriptRepository(db, images, media), images, media);
  }

  testWidgets('기기 sqlite에서 DB 버전 7을 최신으로 올리며 노트 칸을 한 글로 합치고 예전 칸을 지운다', (tester) async {
    final file = File('${tmp.path}/v7.sqlite');
    final raw = sqlite3.open(file.path);
    for (final sql in _v7Schema) {
      raw.execute(sql);
    }
    raw.execute(
      'INSERT INTO scripts (work, gender, age_range, status, favorite, body, created_at, updated_at, situation, medium) '
      "VALUES ('갈매기', 'any', 'any', 'notStarted', 0, '나는 갈매기', "
      "'2026-09-14T10:00:00.000+09:00', '2026-09-14T10:00:00.000+09:00', '호숫가 무대', 'play')",
    );
    raw.execute('PRAGMA user_version = 7');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    expect((await db.select(db.scripts).getSingle()).note, '상황: 호숫가 무대\n\n매체: 연극');
    await db.close();

    final after = sqlite3.open(file.path);
    expect(after.select('PRAGMA user_version').single.values.single, 9);
    final columns = [for (final r in after.select("SELECT name FROM pragma_table_info('scripts')")) r['name']];
    expect(columns, allOf(contains('note'), isNot(contains('situation'))));
    after.close();
  });

  testWidgets('마이크로 녹음하고, 녹음 파일의 길이를 오디오 플레이어로 읽는다', (tester) async {
    final recorder = RecordVoiceRecorder();
    expect(await recorder.hasPermission(), isTrue, reason: '마이크 권한을 미리 허용해 두어야 한다');
    final path = '${tmp.path}/take.m4a';
    await recorder.start(path);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await recorder.stop();
    await recorder.dispose();

    expect(File(path).lengthSync(), greaterThan(0));
    final duration = await PlatformMediaPicker().audioDuration(path);
    // ignore: avoid_print
    print('recorded ${File(path).lengthSync()} bytes, $duration');
    expect(duration, isNotNull);
    expect(duration!.inMilliseconds, inInclusiveRange(1000, 3000));
  });

  testWidgets('영상 파일을 기기 영상 플레이어로 열어 길이를 읽는다', (tester) async {
    final file = File('${tmp.path}/sample.mp4')..writeAsBytesSync(base64Decode(sampleMp4));
    expect(mediaKindOf(file.path), MediaKind.video);
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    // ignore: avoid_print
    print('video ${controller.value.size}, ${controller.value.duration}');
    expect(controller.value.duration.inMilliseconds, inInclusiveRange(800, 1500));
    await controller.dispose();
  });

  testWidgets('영상을 넣은 백업을 내보내고, 다른 저장소에 노트·모음·영상까지 복원한다', (tester) async {
    final (srcDb, src, srcImages, _) = await openStore('src');
    final audition = await src.createCollection('1차 오디션');
    final id = await src.create(ScriptDraft(work: '햄릿', body: '그분이 미치셨다니', note: '상황: 햄릿이 떠난 직후', collectionIds: [audition]));
    final video = File('${tmp.path}/take.mp4')..writeAsBytesSync(base64Decode(sampleMp4));
    await src.importMedia(id, kind: MediaKind.video, sourcePath: video.path, duration: const Duration(seconds: 1));
    final zip = await BackupService(srcDb, src, srcImages).export(tmp, includeMedia: true);

    final (dstDb, dst, dstImages, dstMedia) = await openStore('dst');
    expect(await BackupService(dstDb, dst, dstImages).restore(zip.path), 1);
    final script = (await dst.watchScripts(const ScriptFilter()).first).single.script;
    expect(script.note, '상황: 햄릿이 떠난 직후');
    expect((await dst.watchCollections().first).single.collection.name, '1차 오디션');
    final take = (await dst.watchMedia(script.id).first).single;
    expect(take.kind, MediaKind.video);
    expect(File(dstMedia.pathOf(take.fileName)).readAsBytesSync(), video.readAsBytesSync());
    await srcDb.close();
    await dstDb.close();
  });

  testWidgets('실제 앱 화면: 목록에서 대본을 열고, 노트를 저장하고, 몰입 읽기와 모음 탭을 오간다', (tester) async {
    final (db, repo, images, media) = await openStore('ui');
    final audition = await repo.createCollection('1차 오디션');
    await repo.create(ScriptDraft(
      work: '햄릿',
      body: '그분이 미치셨다니, 그 고귀한 정신이 이렇게 무너지다니.',
      favorite: true,
      collectionIds: [audition],
    ));
    // 처음 켤 때 나오는 사용 방법은 넘긴 상태로 시작한다
    final tips = await AppTips.load();
    await tips.markOnboardingSeen();
    await tester.pumpWidget(AppScope(
      services: AppServices(
        repo: repo,
        images: images,
        media: media,
        ocr: PlatformTextRecognizer(),
        backup: BackupService(db, repo, images),
        settings: await ReadingSettings.load(),
        tips: tips,
        homeView: await HomeViewSettings.load(),
        newRecorder: RecordVoiceRecorder.new,
        mediaPicker: PlatformMediaPicker(),
        screen: PlatformScreenAwake(),
        shareClient: ShareClient(http.Client()),
        shareHistory: await ShareHistory.load(),
        links: PlatformLinkSource(),
      ),
      child: const MonologueApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('즐겨찾기 1편'), findsOneWidget);

    await tester.tap(find.text('햄릿'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('연기 노트'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '상황: 햄릿이 떠난 직후');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect((await repo.watchScripts(const ScriptFilter()).first).single.script.note, '상황: 햄릿이 떠난 직후');

    // 몰입 읽기: 화면을 누르면 메뉴가 나오고 닫을 수 있다
    await tester.tap(find.text('몰입 읽기'));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(Scaffold).last));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('몰입 읽기 닫기'));
    await tester.pumpAndSettle();

    // 넓은 창(아이패드·펼친 폴드)에서는 대본이 목록 옆 칸에 열려서 닫고 돌아갈 화면이 없다
    if (!isWideWindow(tester.element(find.byType(HomeScreen, skipOffstage: false)))) {
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
    // 탭은 폰에서는 아래에, 넓은 창에서는 왼쪽 레일에 있다
    await tester.tap(find.text('모음'));
    await tester.pumpAndSettle();
    expect(find.text('1차 오디션'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
