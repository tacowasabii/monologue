import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/list/script_list_screen.dart';
import 'ui/theme.dart';

class MonologueApp extends StatelessWidget {
  const MonologueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '모노로그',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const ScriptListScreen(),
    );
  }
}
