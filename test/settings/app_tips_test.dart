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

  test('처음 켰을 때의 사용 방법은 넘기고 나면 앱을 다시 켜도 보여 주지 않는다', () async {
    final tips = await AppTips.load();
    expect(tips.onboardingSeen, isFalse);

    await tips.markOnboardingSeen();
    expect(tips.onboardingSeen, isTrue);
    expect((await AppTips.load()).onboardingSeen, isTrue);
  });
}
