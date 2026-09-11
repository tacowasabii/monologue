import 'package:flutter/material.dart';

import 'app.dart';
import 'app_scope.dart';
import 'backup/backup_service.dart';
import 'data/database.dart';
import 'data/image_store.dart';
import 'data/script_repository.dart';
import 'ocr/text_recognizer.dart';
import 'settings/reading_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final images = await ImageStore.open();
  final repo = ScriptRepository(db, images);
  runApp(AppScope(
    services: AppServices(
      repo: repo,
      images: images,
      ocr: MlKitTextRecognizer(),
      backup: BackupService(db, repo, images),
      settings: await ReadingSettings.load(),
    ),
    child: const MonologueApp(),
  ));
}
