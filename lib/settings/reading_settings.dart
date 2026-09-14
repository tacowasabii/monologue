import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// 대본 보기 화면의 글자 크기와 앱 화면 모드(기기 설정 따라가기·밝게·어둡게).
class ReadingSettings extends ChangeNotifier {
  ReadingSettings._(this._prefs, this._fontSize, this._themeMode);

  static const min = 14.0;
  static const max = 32.0;
  static const _key = 'reading.fontSize';
  static const _themeModeKey = 'display.themeMode';

  final SharedPreferencesAsync _prefs;
  double _fontSize;
  ThemeMode _themeMode;

  static Future<ReadingSettings> load() async {
    final prefs = SharedPreferencesAsync();
    final themeMode = ThemeMode.values.asNameMap()[await prefs.getString(_themeModeKey)] ?? ThemeMode.system;
    return ReadingSettings._(prefs, (await prefs.getDouble(_key)) ?? 20, themeMode);
  }

  double get fontSize => _fontSize;

  ThemeMode get themeMode => _themeMode;

  Future<void> setFontSize(double value) async {
    _fontSize = value.clamp(min, max);
    notifyListeners();
    await _prefs.setDouble(_key, _fontSize);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (value == _themeMode) return;
    _themeMode = value;
    notifyListeners();
    // 기억하지 못해도 이번 실행 동안은 고른 모드로 보여 준다
    try {
      await _prefs.setString(_themeModeKey, value.name);
    } catch (_) {}
  }
}
