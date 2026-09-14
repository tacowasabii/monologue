import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../domain/script_draft.dart';
import '../../platform/screen_awake.dart';
import '../common/adaptive.dart';
import '../common/korean_text.dart';
import 'script_body.dart';

/// 메뉴 없이 대본만 보여준다. 상태 표시줄을 숨기고 화면이 꺼지지 않게 하며, 탭하면 메뉴가 나온다.
class ImmersiveReaderScreen extends StatefulWidget {
  const ImmersiveReaderScreen({super.key, required this.script, this.focusSpeaker});

  final Script script;
  final String? focusSpeaker;

  @override
  State<ImmersiveReaderScreen> createState() => _ImmersiveReaderScreenState();
}

class _ImmersiveReaderScreenState extends State<ImmersiveReaderScreen> {
  ScreenAwake? _screen;
  bool _chrome = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_screen != null) return;
    _screen = AppScope.of(context).screen..keepOn(true);
  }

  @override
  void dispose() {
    _screen?.keepOn(false);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = AppScope.of(context).settings;
    final s = widget.script;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _chrome = !_chrome),
        child: Stack(
          children: [
            SafeArea(
              child: ListenableBuilder(
                listenable: settings,
                builder: (context, _) => ListView(
                  padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(28, 56, 28, 120)),
                  children: [
                    Text(keepWords(s.work ?? firstLineOf(s.body)), style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 40),
                    ScriptBody(
                      body: s.body,
                      dialogue: s.dialogue,
                      fontSize: settings.fontSize,
                      focusSpeaker: widget.focusSpeaker,
                      selectable: false,
                    ),
                  ],
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !_chrome,
              child: AnimatedOpacity(
                opacity: _chrome ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: '몰입 읽기 닫기',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          tooltip: '글자 작게',
                          icon: const Icon(Icons.text_decrease_rounded),
                          onPressed: () => settings.setFontSize(settings.fontSize - 2),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: '글자 크게',
                          icon: const Icon(Icons.text_increase_rounded),
                          onPressed: () => settings.setFontSize(settings.fontSize + 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
