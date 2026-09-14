import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../practice/voice_recorder.dart';
import '../common/adaptive.dart';
import '../common/format.dart';
import '../common/korean_text.dart';
import '../theme.dart';

/// 녹음을 마치고 저장소에 남은 파일
typedef RecordedTake = ({String fileName, Duration duration});

/// 대본을 보면서 녹음한다. 멈추면 [RecordedTake]를 돌려주고, 버리고 나가면 null.
class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key, required this.body});

  final String body;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  VoiceRecorder? _recorder;
  final _watch = Stopwatch();
  Timer? _ticker;
  String? _fileName;
  bool _recording = false;
  bool _starting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recorder ??= AppScope.of(context).newRecorder();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder?.dispose();
    super.dispose();
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _start() async {
    if (_starting) return;
    final media = AppScope.of(context).media;
    setState(() => _starting = true);
    try {
      if (!await _recorder!.hasPermission()) {
        if (mounted) _snack('마이크 권한이 필요해요. 설정 앱에서 허용해 주세요.');
        return;
      }
      final name = media.newFileName('.m4a');
      await _recorder!.start(media.pathOf(name));
      if (!mounted) return;
      _watch
        ..reset()
        ..start();
      _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted) setState(() {});
      });
      setState(() {
        _fileName = name;
        _recording = true;
      });
    } catch (_) {
      if (mounted) _snack('녹음을 시작하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// PopScope가 바뀐 상태를 읽은 뒤에 닫히도록 다음 프레임에 pop한다.
  void _finish(RecordedTake? result) {
    _ticker?.cancel();
    _watch.stop();
    setState(() => _recording = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  Future<void> _stopAndSave() async {
    _watch.stop();
    final elapsed = _watch.elapsed;
    await _recorder!.stop();
    if (!mounted) return;
    _finish((fileName: _fileName!, duration: elapsed));
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('녹음을 버릴까요?'),
        content: const Text('지금까지 녹음한 내용은 저장되지 않아요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('계속 녹음')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('버리기'),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return;
    final media = AppScope.of(context).media;
    await _recorder!.cancel();
    final name = _fileName;
    if (name != null) await media.delete(name);
    if (mounted) _finish(null);
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PopScope(
      canPop: !_recording,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('녹음')),
        body: ListenableBuilder(
          listenable: services.settings,
          builder: (context, _) => SingleChildScrollView(
            padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(24, 8, 24, 32)),
            child: Text(
              keepWords(widget.body),
              style: TextStyle(
                fontFamily: serifFamily,
                fontSize: services.settings.fontSize,
                height: 1.85,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: SafeArea(
            child: Padding(
              // 넓은 창에서는 녹음 시간과 버튼이 양끝으로 멀어지지 않게 본문 폭에 맞춘다
              padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(20, 12, 20, 12)),
              child: Row(
                children: [
                  if (_recording) ...[
                    Icon(Icons.fiber_manual_record_rounded, color: scheme.error, size: 14),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    formatDuration(_watch.elapsed),
                    style: theme.textTheme.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  const Spacer(),
                  if (_recording)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                      onPressed: _stopAndSave,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('멈추고 저장'),
                    )
                  else
                    FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                      onPressed: _starting ? null : _start,
                      icon: const Icon(Icons.fiber_manual_record_rounded),
                      label: const Text('녹음 시작'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
