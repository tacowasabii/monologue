import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:monologue/app_scope.dart';
import 'package:monologue/backup/backup_service.dart';
import 'package:monologue/data/database.dart';
import 'package:monologue/data/image_store.dart';
import 'package:monologue/data/media_store.dart';
import 'package:monologue/data/script_repository.dart';
import 'package:monologue/ocr/assemble_text.dart';
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
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeRecognizer implements TextRecognizing {
  @override
  Future<List<OcrBlock>> recognize(String imagePath) async => const [];
}

class FakeScreenAwake implements ScreenAwake {
  final calls = <bool>[];

  @override
  Future<void> keepOn(bool on) async => calls.add(on);
}

/// 마이크 대신 짧은 파일을 써 두는 녹음기
class FakeRecorder implements VoiceRecorder {
  bool permission = true;
  String? startedPath;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> start(String path) async {
    startedPath = path;
    File(path).writeAsBytesSync([1, 2, 3]);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {
    final path = startedPath;
    if (path != null && File(path).existsSync()) File(path).deleteSync();
  }

  @override
  Future<void> dispose() async {}
}

/// 카메라·파일 선택 대신 [next]를 돌려준다(null이면 취소한 것). 어느 쪽을 열었는지 [calls]에 남긴다.
class FakeMediaPicker implements MediaPicker {
  PickedMedia? next;
  final calls = <String>[];

  @override
  Future<PickedMedia?> recordVideo() async {
    calls.add('camera');
    return next;
  }

  @override
  Future<PickedMedia?> pickFromGallery() async {
    calls.add('gallery');
    return next;
  }

  @override
  Future<PickedMedia?> pickFromFiles() async {
    calls.add('files');
    return next;
  }

  /// 파일에서 읽었다고 돌려줄 길이(null이면 읽지 못한 것)
  Duration? audioLength;

  @override
  Future<Duration?> audioDuration(String path) async => audioLength;
}

/// 공유 서버 대신 [handler]가 답한다. 받은 요청은 [requests]에 남긴다. 기본은 서버 오류(503).
class FakeShareServer {
  http.Response Function(http.Request request) handler = (_) => http.Response('', 503);
  final requests = <http.Request>[];

  /// 응답하기 전에 기다릴 것(예: 업로드가 끝나기 전에 다른 동작을 끼워 넣는 테스트용). 기본은 곧바로 응답.
  Future<void> Function(http.Request request)? beforeRespond;

  late final MockClient client = MockClient((request) async {
    requests.add(request);
    final wait = beforeRespond;
    if (wait != null) await wait(request);
    return handler(request);
  });
}

/// 앱을 여는 링크를 테스트에서 직접 흘려보낸다
class FakeLinkSource implements LinkSource {
  final _controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get links => _controller.stream;

  void open(Uri uri) => _controller.add(uri);
}

http.Response jsonResponse(Object? body, int status) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

class Harness {
  Harness._(this.db, this.services, this.recorder, this.picker, this.screen, this.shareServer, this.links);

  final AppDatabase db;
  final AppServices services;
  final FakeRecorder recorder;
  final FakeMediaPicker picker;
  final FakeScreenAwake screen;
  final FakeShareServer shareServer;
  final FakeLinkSource links;

  static Future<Harness> create() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final images = ImageStore(Directory.systemTemp.createTempSync('monologue_ui'));
    final media = MediaStore(Directory.systemTemp.createTempSync('monologue_media'));
    final repo = ScriptRepository(db, images, media);
    final recorder = FakeRecorder();
    final picker = FakeMediaPicker();
    final screen = FakeScreenAwake();
    final shareServer = FakeShareServer();
    final links = FakeLinkSource();
    return Harness._(
      db,
      AppServices(
        repo: repo,
        images: images,
        media: media,
        ocr: FakeRecognizer(),
        backup: BackupService(db, repo, images),
        settings: await ReadingSettings.load(),
        tips: await AppTips.load(),
        homeView: await HomeViewSettings.load(),
        newRecorder: () => recorder,
        mediaPicker: picker,
        screen: screen,
        shareClient: ShareClient(shareServer.client),
        shareHistory: await ShareHistory.load(),
        links: links,
      ),
      recorder,
      picker,
      screen,
      shareServer,
      links,
    );
  }

  Widget wrap(Widget child) => AppScope(
        services: services,
        child: MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: child,
        ),
      );
}
