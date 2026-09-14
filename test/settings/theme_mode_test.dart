import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/settings/reading_settings.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('화면 모드는 기기 설정을 따라가며 시작하고, 고른 모드를 앱을 다시 켜도 기억한다', () async {
    final settings = await ReadingSettings.load();
    expect(settings.themeMode, ThemeMode.system);

    await settings.setThemeMode(ThemeMode.dark);
    expect(settings.themeMode, ThemeMode.dark);
    final reloaded = await ReadingSettings.load();
    expect(reloaded.themeMode, ThemeMode.dark);
    expect(reloaded.fontSize, 20);
  });
}
