import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/script_repository.dart';
import '../../domain/dialogue.dart';
import '../../domain/enums.dart';
import '../../domain/script_notes.dart';
import '../../settings/reading_settings.dart';
import '../common/korean_text.dart';
import '../common/pill_chip.dart';
import '../edit/script_edit_screen.dart';
import '../notes/notes_screen.dart';
import '../theme.dart';
import 'image_viewer_screen.dart';
import 'immersive_reader_screen.dart';
import 'script_body.dart';

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
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) {
              final theme = Theme.of(context);
              final scheme = theme.colorScheme;
              TextStyle glyph(double size) => TextStyle(fontFamily: serifFamily, fontSize: size, color: scheme.onSurfaceVariant);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('글자 크기', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.topLeft,
                      child: Text(
                        '나는 늘 괜찮다고 말했어.',
                        style: TextStyle(fontFamily: serifFamily, fontSize: settings.fontSize, height: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('가', style: glyph(14)),
                      Expanded(
                        child: Slider(
                          min: ReadingSettings.min,
                          max: ReadingSettings.max,
                          divisions: 9,
                          value: settings.fontSize,
                          label: settings.fontSize.round().toString(),
                          onChanged: settings.setFontSize,
                        ),
                      ),
                      Text('가', style: glyph(24)),
                    ],
                  ),
                ],
              );
            },
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
        final scheme = theme.colorScheme;
        final source = s.work;
        final memo = s.memo;
        final traits = [
          if (s.gender != Gender.any) s.gender.label,
          if (s.ageRange != AgeRange.any) s.ageRange.label,
        ];
        final hasLabels = traits.isNotEmpty || d.tags.isNotEmpty;
        final speakers = s.dialogue ? speakersOf(parseDialogue(s.body)) : const <String>[];
        // 본문을 고쳐 저장된 역할이 사라졌으면 강조하지 않는다
        final focus = speakers.contains(s.myRole) ? s.myRole : null;
        final notes = s.notes;
        final showNotes = notes.situation != null || notes.objective != null;
        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: s.favorite ? '즐겨찾기 해제' : '즐겨찾기',
                icon: Icon(s.favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: s.favorite ? favoriteColor(scheme) : null),
                onPressed: () => services.repo.setFavorite(s.id, !s.favorite),
              ),
              IconButton(
                tooltip: '노트',
                icon: const Icon(Icons.sticky_note_2_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => NotesScreen(script: s)),
                ),
              ),
              IconButton(
                tooltip: '편집',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<int>(builder: (_) => ScriptEditScreen(existing: d)),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded),
                position: PopupMenuPosition.under,
                onSelected: (v) {
                  if (v == 'images') {
                    Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => ImageViewerScreen(
                        paths: [for (final i in d.images) services.images.pathOf(i.fileName)],
                      ),
                    ));
                  } else if (v == 'fontSize') {
                    _showFontSize(services.settings);
                  } else if (v == 'delete') {
                    _delete(d);
                  }
                },
                itemBuilder: (_) => [
                  if (d.images.isNotEmpty)
                    PopupMenuItem(
                      value: 'images',
                      child: _MenuRow(icon: Icons.photo_library_outlined, text: '원본 보기 (${d.images.length})'),
                    ),
                  const PopupMenuItem(
                    value: 'fontSize',
                    child: _MenuRow(icon: Icons.format_size_rounded, text: '글자 크기'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: _MenuRow(icon: Icons.delete_outline_rounded, text: '삭제', color: scheme.error),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => ImmersiveReaderScreen(script: s, focusSpeaker: focus),
            )),
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('몰입 읽기'),
          ),
          body: ListView(
            // 몰입 읽기 버튼이 본문 끝을 가리지 않게 아래를 넉넉히 둔다
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 112),
            children: [
              if (source != null) Text(keepWords(source), style: theme.textTheme.headlineMedium?.copyWith(height: 1.3)),
              if (hasLabels)
                Padding(
                  padding: EdgeInsets.only(top: source != null ? 14 : 0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in traits) _Label(t),
                      for (final t in d.tags) _Label('#$t', accent: true),
                    ],
                  ),
                ),
              if (memo != null)
                Padding(
                  padding: EdgeInsets.only(top: source != null || hasLabels ? 16 : 0),
                  child: Text(
                    keepWords(memo),
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.6),
                  ),
                ),
              if (speakers.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: source != null || hasLabels || memo != null ? 20 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('내 역할', style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final name in speakers)
                            PillChip(
                              label: name,
                              selected: name == focus,
                              onSelected: (_) => services.repo.setMyRole(s.id, name == focus ? null : name),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (showNotes)
                Padding(
                  padding: EdgeInsets.only(
                    top: source != null || hasLabels || memo != null || speakers.isNotEmpty ? 20 : 0,
                  ),
                  child: _NotesSummary(
                    notes: notes,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => NotesScreen(script: s)),
                    ),
                  ),
                ),
              // 위에 보여 줄 정보가 없으면 구분선 없이 본문부터 시작한다
              if (source != null || hasLabels || memo != null || speakers.isNotEmpty || showNotes) ...[
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: 28, height: 2, color: scheme.primary.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 24),
              ],
              ListenableBuilder(
                listenable: services.settings,
                builder: (context, _) => ScriptBody(
                  body: s.body,
                  dialogue: s.dialogue,
                  fontSize: services.settings.fontSize,
                  focusSpeaker: focus,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(text, style: color == null ? null : TextStyle(color: color)),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent ? scheme.primaryContainer : Colors.transparent,
        border: Border.all(color: accent ? Colors.transparent : scheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: accent ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 본문 위에 상황·원하는 것을 짧게 보여 주고, 누르면 노트 화면을 연다.
class _NotesSummary extends StatelessWidget {
  const _NotesSummary({required this.notes, required this.onTap});

  final ScriptNotes notes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                keepWords(value),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        );
    return Material(
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.outlineVariant)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (notes.situation case final v?) row('상황', v),
              if (notes.objective case final v?) row('원하는 것', v),
            ],
          ),
        ),
      ),
    );
  }
}
