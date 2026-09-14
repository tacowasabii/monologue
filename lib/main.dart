import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'app_scope.dart';
import 'backup/backup_service.dart';
import 'data/database.dart';
import 'data/image_store.dart';
import 'data/media_store.dart';
import 'data/script_repository.dart';
import 'ocr/text_recognizer.dart';
import 'platform/screen_awake.dart';
import 'practice/media_picker.dart';
import 'practice/voice_recorder.dart';
import 'settings/app_tips.dart';
import 'settings/home_view_settings.dart';
import 'settings/reading_settings.dart';
import 'share/link_source.dart';
import 'share/share_client.dart';
import 'share/share_history.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Gowun Batang'], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  final db = AppDatabase();
  final images = await ImageStore.open();
  final media = await MediaStore.open();
  final repo = ScriptRepository(db, images, media);
  runApp(AppScope(
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
    child: const MonologueApp(),
  ));
}
