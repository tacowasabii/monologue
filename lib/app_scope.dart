import 'package:flutter/widgets.dart';

import 'backup/backup_service.dart';
import 'data/image_store.dart';
import 'data/script_repository.dart';
import 'ocr/text_recognizer.dart';
import 'settings/app_tips.dart';
import 'settings/home_view_settings.dart';
import 'settings/reading_settings.dart';

class AppServices {
  const AppServices({
    required this.repo,
    required this.images,
    required this.ocr,
    required this.backup,
    required this.settings,
    required this.tips,
    required this.homeView,
  });

  final ScriptRepository repo;
  final ImageStore images;
  final TextRecognizing ocr;
  final BackupService backup;
  final ReadingSettings settings;
  final AppTips tips;
  final HomeViewSettings homeView;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
