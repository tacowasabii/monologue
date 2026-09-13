import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'app_scope.dart';
import 'backup/backup_service.dart';
import 'data/database.dart';
import 'data/image_store.dart';
import 'data/script_repository.dart';
import 'ocr/text_recognizer.dart';
import 'platform/screen_awake.dart';
import 'settings/app_tips.dart';
import 'settings/reading_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Gowun Batang'], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  final db = AppDatabase();
  final images = await ImageStore.open();
  final repo = ScriptRepository(db, images);
  runApp(AppScope(
    services: AppServices(
      repo: repo,
      images: images,
      ocr: PlatformTextRecognizer(),
      backup: BackupService(db, repo, images),
      settings: await ReadingSettings.load(),
      tips: await AppTips.load(),
      screen: PlatformScreenAwake(),
    ),
    child: const MonologueApp(),
  ));
}
