import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/script_filter.dart';

enum HomeLayout { grid, list }

/// 모음을 그리드로 볼지 목록으로 볼지, 대본 목록을 어떤 순서로 볼지. 마지막 선택을 기억한다.
class HomeViewSettings extends ChangeNotifier {
  HomeViewSettings._(this._prefs, this._layout, this._sort);

  static const _layoutKey = 'home.layout';
  static const _sortKey = 'home.sort';

  final SharedPreferencesAsync _prefs;
  HomeLayout _layout;
  ScriptSort _sort;

  static Future<HomeViewSettings> load() async {
    final prefs = SharedPreferencesAsync();
    final layout = await prefs.getString(_layoutKey);
    final sort = await prefs.getString(_sortKey);
    return HomeViewSettings._(
      prefs,
      HomeLayout.values.asNameMap()[layout] ?? HomeLayout.grid,
      ScriptSort.values.asNameMap()[sort] ?? ScriptSort.updated,
    );
  }

  HomeLayout get layout => _layout;

  ScriptSort get sort => _sort;

  Future<void> setLayout(HomeLayout value) async {
    if (value == _layout) return;
    _layout = value;
    notifyListeners();
    await _save(_layoutKey, value.name);
  }

  Future<void> setSort(ScriptSort value) async {
    if (value == _sort) return;
    _sort = value;
    notifyListeners();
    await _save(_sortKey, value.name);
  }

  // 기억하지 못해도 이번 실행 동안은 바뀐 방식으로 보여 준다
  Future<void> _save(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (_) {}
  }
}
