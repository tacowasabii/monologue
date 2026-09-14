import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'ui/home/home_screen.dart';
import 'ui/share/incoming_links.dart';
import 'ui/theme.dart';

class MonologueApp extends StatefulWidget {
  const MonologueApp({super.key});

  @override
  State<MonologueApp> createState() => _MonologueAppState();
}

class _MonologueAppState extends State<MonologueApp> {
  /// 공유 링크가 오면 어느 화면에 있든 받은 대본 화면을 올린다
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    // 설정에서 고른 화면 모드(기기 설정 따라가기·밝게·어둡게)를 바로 반영한다
    return IncomingLinks(
      navigatorKey: _navigatorKey,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          navigatorKey: _navigatorKey,
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
      ),
    );
  }
}
