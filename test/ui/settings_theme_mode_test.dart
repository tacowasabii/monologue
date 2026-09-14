import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/app.dart';
import 'package:monologue/app_scope.dart';
import 'package:monologue/ui/home/home_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'test_harness.dart';

void main() {
  setUp(() => PackageInfo.setMockInitialValues(
        appName: '모노로그',
        packageName: 'com.tacowasabii.monologue',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      ));

  testWidgets('설정에서 화면 모드를 고르면 저장되고 앱 전체가 그 모드로 바뀐다', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final h = (await tester.runAsync(Harness.create))!;
    await tester.pumpWidget(AppScope(services: h.services, child: const MonologueApp()));
    await tester.pumpAndSettle();
    // 테스트 기기는 밝은 모드라, 기기 설정을 따라가면 밝게 보인다
    expect(Theme.of(tester.element(find.byType(HomeScreen))).brightness, Brightness.light);

    // 대본 탭과 모음 탭이 모두 만들어져 있어서 보이는 첫 탭의 설정 버튼을 누른다
    await tester.tap(find.byTooltip('설정').first);
    await tester.pumpAndSettle();
    expect(find.text('화면 모드'), findsOneWidget);

    await tester.tap(find.text('어둡게'));
    await tester.pumpAndSettle();
    expect(h.services.settings.themeMode, ThemeMode.dark);
    expect(Theme.of(tester.element(find.text('화면 모드'))).brightness, Brightness.dark);

    await tester.tap(find.text('기기 설정'));
    await tester.pumpAndSettle();
    expect(h.services.settings.themeMode, ThemeMode.system);
    expect(Theme.of(tester.element(find.text('화면 모드'))).brightness, Brightness.light);
    await tester.runAsync(h.db.close);
  });
}
