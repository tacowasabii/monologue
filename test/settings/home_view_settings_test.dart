import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/script_filter.dart';
import 'package:monologue/settings/home_view_settings.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('첫 화면은 그리드로 시작하고, 고른 보기 방식을 앱을 다시 켜도 기억한다', () async {
    final settings = await HomeViewSettings.load();
    expect(settings.layout, HomeLayout.grid);

    await settings.setLayout(HomeLayout.list);
    expect(settings.layout, HomeLayout.list);
    expect((await HomeViewSettings.load()).layout, HomeLayout.list);
  });

  test('대본 목록은 최근 수정순으로 시작하고, 고른 정렬을 앱을 다시 켜도 기억한다', () async {
    final settings = await HomeViewSettings.load();
    expect(settings.sort, ScriptSort.updated);

    await settings.setSort(ScriptSort.work);
    expect(settings.sort, ScriptSort.work);
    final reloaded = await HomeViewSettings.load();
    expect(reloaded.sort, ScriptSort.work);
    expect(reloaded.layout, HomeLayout.grid);
  });
}
