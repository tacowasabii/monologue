import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HomeLayout { grid, list }

/// 첫 화면에서 모음을 그리드로 볼지 목록으로 볼지. 마지막 선택을 기억한다.
class HomeViewSettings extends ChangeNotifier {
  HomeViewSettings._(this._prefs, this._layout);

  static const _key = 'home.layout';

  final SharedPreferencesAsync _prefs;
  HomeLayout _layout;

  static Future<HomeViewSettings> load() async {
    final prefs = SharedPreferencesAsync();
    final saved = await prefs.getString(_key);
    return HomeViewSettings._(prefs, HomeLayout.values.asNameMap()[saved] ?? HomeLayout.grid);
  }

  HomeLayout get layout => _layout;

  Future<void> setLayout(HomeLayout value) async {
    if (value == _layout) return;
    _layout = value;
    notifyListeners();
    // 기억하지 못해도 이번 실행 동안은 바뀐 방식으로 보여 준다
    try {
      await _prefs.setString(_key, value.name);
    } catch (_) {}
  }
}
