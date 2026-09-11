import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/script_repository.dart';
import '../../domain/enums.dart';
import '../../settings/reading_settings.dart';
import '../edit/script_edit_screen.dart';
import 'image_viewer_screen.dart';

class ScriptViewScreen extends StatefulWidget {
  const ScriptViewScreen({super.key, required this.scriptId});

  final int scriptId;

  @override
  State<ScriptViewScreen> createState() => _ScriptViewScreenState();
}

class _ScriptViewScreenState extends State<ScriptViewScreen> {
  Stream<ScriptDetail?>? _detail;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detail ??= AppScope.of(context).repo.watchScript(widget.scriptId);
  }

  Future<void> _delete(ScriptDetail d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대본 삭제'),
        content: const Text('이 대본을 삭제할까요? 원본 사진도 함께 지워져요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final repo = AppScope.of(context).repo;
    Navigator.of(context).pop();
    await repo.delete(d.script.id);
  }

  void _showFontSize(ReadingSettings settings) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('글자 크기', style: Theme.of(context).textTheme.titleMedium),
                Slider(
                  min: ReadingSettings.min,
                  max: ReadingSettings.max,
                  divisions: 9,
                  value: settings.fontSize,
                  label: settings.fontSize.round().toString(),
                  onChanged: settings.setFontSize,
                ),
                Text('나는 늘 괜찮다고 말했어.', style: TextStyle(fontSize: settings.fontSize)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    return StreamBuilder<ScriptDetail?>(
      stream: _detail,
      builder: (context, snap) {
        final d = snap.data;
        if (d == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: snap.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator()
                  : const Text('대본을 찾을 수 없어요'),
            ),
          );
        }
        final s = d.script;
        final theme = Theme.of(context);
        final meta = [
          s.work,
          s.character,
          if (s.gender != Gender.any) s.gender.label,
          if (s.ageRange != AgeRange.any) s.ageRange.label,
        ].whereType<String>().join(' · ');
        return Scaffold(
          appBar: AppBar(
            title: Text(s.title, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: s.favorite ? '즐겨찾기 해제' : '즐겨찾기',
                icon: Icon(s.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: s.favorite ? Colors.amber.shade600 : null),
                onPressed: () => services.repo.setFavorite(s.id, !s.favorite),
              ),
              IconButton(
                tooltip: '글자 크기',
                icon: const Icon(Icons.format_size),
                onPressed: () => _showFontSize(services.settings),
              ),
              IconButton(
                tooltip: '편집',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<int>(builder: (_) => ScriptEditScreen(existing: d)),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'images') {
                    Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => ImageViewerScreen(
                        paths: [for (final i in d.images) services.images.pathOf(i.fileName)],
                      ),
                    ));
                  } else if (v == 'delete') {
                    _delete(d);
                  }
                },
                itemBuilder: (_) => [
                  if (d.images.isNotEmpty) PopupMenuItem(value: 'images', child: Text('원본 보기 (${d.images.length})')),
                  const PopupMenuItem(value: 'delete', child: Text('삭제')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
            children: [
              if (meta.isNotEmpty)
                Text(meta, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              if (d.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in d.tags) Chip(label: Text('#$t'), visualDensity: VisualDensity.compact),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SegmentedButton<PracticeStatus>(
                segments: [
                  for (final st in PracticeStatus.values) ButtonSegment(value: st, label: Text(st.label)),
                ],
                selected: {s.status},
                showSelectedIcon: false,
                onSelectionChanged: (v) => services.repo.setStatus(s.id, v.first),
              ),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: services.settings,
                builder: (context, _) => SelectableText(
                  s.body,
                  style: TextStyle(fontSize: services.settings.fontSize, height: 1.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
