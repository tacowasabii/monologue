import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 대본 보기 화면의 글자 크기.
class ReadingSettings extends ChangeNotifier {
  ReadingSettings._(this._prefs, this._fontSize);

  static const min = 14.0;
  static const max = 32.0;
  static const _key = 'reading.fontSize';

  final SharedPreferencesAsync _prefs;
  double _fontSize;

  static Future<ReadingSettings> load() async {
    final prefs = SharedPreferencesAsync();
    return ReadingSettings._(prefs, (await prefs.getDouble(_key)) ?? 20);
  }

  double get fontSize => _fontSize;

  Future<void> setFontSize(double value) async {
    _fontSize = value.clamp(min, max);
    notifyListeners();
    await _prefs.setDouble(_key, _fontSize);
  }
}
