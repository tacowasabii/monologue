import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/settings/app_tips.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('사진 보관 안내는 한 번만 보여 주고, 앱을 다시 켜도 기억한다', () async {
    final tips = await AppTips.load();
    expect(await tips.takePhotoKept(), isTrue);
    expect(await tips.takePhotoKept(), isFalse);

    final reopened = await AppTips.load();
    expect(await reopened.takePhotoKept(), isFalse);
  });
}
