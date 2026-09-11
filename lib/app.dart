import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/list/script_list_screen.dart';

const seedColor = Color(0xFF7A4B5C);

class MonologueApp extends StatelessWidget {
  const MonologueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '모노로그',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seedColor, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seedColor, brightness: Brightness.dark),
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const ScriptListScreen(),
    );
  }
}
