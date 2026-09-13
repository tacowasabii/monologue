import 'package:flutter/widgets.dart';

import 'backup/backup_service.dart';
import 'data/image_store.dart';
import 'data/media_store.dart';
import 'data/script_repository.dart';
import 'ocr/text_recognizer.dart';
import 'practice/media_picker.dart';
import 'practice/voice_recorder.dart';
import 'settings/app_tips.dart';
import 'settings/home_view_settings.dart';
import 'settings/reading_settings.dart';

class AppServices {
  const AppServices({
    required this.repo,
    required this.images,
    required this.media,
    required this.ocr,
    required this.backup,
    required this.settings,
    required this.tips,
    required this.homeView,
    required this.newRecorder,
    required this.mediaPicker,
  });

  final ScriptRepository repo;
  final ImageStore images;
  final MediaStore media;
  final TextRecognizing ocr;
  final BackupService backup;
  final ReadingSettings settings;
  final AppTips tips;
  final HomeViewSettings homeView;

  /// 녹음 화면마다 새 녹음기를 만든다(녹음기는 화면을 닫을 때 정리한다).
  final VoiceRecorder Function() newRecorder;
  final MediaPicker mediaPicker;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}
