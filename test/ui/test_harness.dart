import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:monologue/app_scope.dart';
import 'package:monologue/backup/backup_service.dart';
import 'package:monologue/data/database.dart';
import 'package:monologue/data/image_store.dart';
import 'package:monologue/data/media_store.dart';
import 'package:monologue/data/script_repository.dart';
import 'package:monologue/ocr/assemble_text.dart';
import 'package:monologue/ocr/text_recognizer.dart';
import 'package:monologue/settings/app_tips.dart';
import 'package:monologue/settings/home_view_settings.dart';
import 'package:monologue/settings/reading_settings.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeRecognizer implements TextRecognizing {
  @override
  Future<List<OcrBlock>> recognize(String imagePath) async => const [];
}

class Harness {
  Harness._(this.db, this.services);

  final AppDatabase db;
  final AppServices services;

  static Future<Harness> create() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    final images = ImageStore(Directory.systemTemp.createTempSync('monologue_ui'));
    final media = MediaStore(Directory.systemTemp.createTempSync('monologue_media'));
    final repo = ScriptRepository(db, images, media);
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
      ),
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
