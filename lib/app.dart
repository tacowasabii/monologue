import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'ui/home/home_screen.dart';
import 'ui/theme.dart';

class MonologueApp extends StatelessWidget {
  const MonologueApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    // 설정에서 고른 화면 모드(기기 설정 따라가기·밝게·어둡게)를 바로 반영한다
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: '모노로그',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: settings.themeMode,
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomeScreen(),
      ),
    );
  }
}
