import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/script_repository.dart';
import '../../domain/dialogue.dart';
import '../../settings/reading_settings.dart';
import '../common/adaptive.dart';
import '../common/korean_text.dart';
import '../common/pill_chip.dart';
import '../design/design.dart';
import '../edit/script_edit_screen.dart';
import '../notes/notes_screen.dart';
import '../practice/practice_section.dart';
import '../share/share_script_flow.dart';
import '../theme.dart';
import 'image_viewer_screen.dart';
import 'immersive_reader_screen.dart';
import 'script_body.dart';

class ScriptViewScreen extends StatefulWidget {
  const ScriptViewScreen({super.key, required this.scriptId, this.onDeleted, this.popWhenWide = false});

  final int scriptId;

  /// 넓은 창에서 목록 옆 칸에 넣어 보여 줄 때 준다. 대본이 지워지면 부르고, 뒤로 가기 버튼은 두지 않는다.
  final VoidCallback? onDeleted;

  /// 좁은 창에서 목록 위에 띄운 화면이면 true. 창이 넓어지면(폴드를 펼치면) 스스로 닫고 true를 돌려주어
  /// 목록 옆 칸에서 이어 보게 한다.
  final bool popWhenWide;

  @override
  State<ScriptViewScreen> createState() => _ScriptViewScreenState();
}

class _ScriptViewScreenState extends State<ScriptViewScreen> {
  Stream<ScriptDetail?>? _detail;
  bool _returningToList = false;

  /// iPad에서 공유 시트를 ⋯ 버튼 옆에 띄우려고 버튼 위치를 잰다
  final _menuKey = GlobalKey();

  bool get _inPane => widget.onDeleted != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detail ??= AppScope.of(context).repo.watchScript(widget.scriptId);
  }

  Future<void> _delete(ScriptDetail d) async {
    final ok = await showConfirmDialog(
      context,
      title: '이 대본을 삭제할까요?',
      message: '원본 사진과 연습 기록도 함께 지워져요.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final repo = AppScope.of(context).repo;
    if (widget.onDeleted case final onDeleted?) {
      onDeleted();
    } else {
      Navigator.of(context).pop();
    }
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
                  const AppSheetHeader(title: '글자 크기'),
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

  /// [ScriptViewScreen.popWhenWide] 화면이 맨 위에 있을 때 창이 넓어지면 닫고 목록 옆 칸으로 넘긴다.
  /// 편집 화면처럼 다른 화면이 위에 떠 있으면, 그 화면을 닫고 돌아왔을 때 넘긴다.
  void _returnToListIfWide() {
    if (!widget.popWhenWide || _returningToList) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent || !isWideWindow(context)) return;
    _returningToList = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _returningToList = false;
      if (mounted && route.isCurrent) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    _returnToListIfWide();
    final services = AppScope.of(context);
    return StreamBuilder<ScriptDetail?>(
      stream: _detail,
      builder: (context, snap) {
        final d = snap.data;
        if (d == null) {
          final waiting = snap.connectionState == ConnectionState.waiting;
          // 옆 칸에서 보던 대본이 다른 화면에서 지워졌으면 옆 칸을 비운다
          if (!waiting && _inPane) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onDeleted!();
            });
          }
          return Scaffold(
            appBar: AppBar(automaticallyImplyLeading: !_inPane),
            body: Center(
              child: waiting ? const CircularProgressIndicator() : const Text('대본을 찾을 수 없어요'),
            ),
          );
        }
        final s = d.script;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final source = s.work;
        final memo = s.memo;
        final hasLabels = d.tags.isNotEmpty;
        final speakers = s.dialogue ? speakersOf(parseDialogue(s.body)) : const <String>[];
        // 본문을 고쳐 저장된 역할이 사라졌으면 강조하지 않는다
        final focus = speakers.contains(s.myRole) ? s.myRole : null;
        final note = s.note;
        void openNotes() => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => NotesScreen(script: s)),
            );
        void openReader() => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => ImmersiveReaderScreen(script: s, focusSpeaker: focus)),
            );
        const readerIcon = Icon(Icons.menu_book_rounded);
        const readerLabel = Text('몰입 읽기');
        return Scaffold(
          appBar: AppBar(
            // 목록 옆 칸에서는 뒤로 가기를 목록 쪽 화면에만 둔다
            automaticallyImplyLeading: !_inPane,
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
                onPressed: openNotes,
              ),
              IconButton(
                tooltip: '편집',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<int>(builder: (_) => ScriptEditScreen(existing: d)),
                ),
              ),
              PopupMenuButton<String>(
                key: _menuKey,
                icon: const Icon(Icons.more_horiz_rounded),
                position: PopupMenuPosition.under,
                onSelected: (v) {
                  if (v == 'share') {
                    final box = _menuKey.currentContext?.findRenderObject() as RenderBox?;
                    shareScriptByLink(context, d, anchor: box == null ? null : box.localToGlobal(Offset.zero) & box.size);
                    return;
                  }
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
                  const PopupMenuItem(
                    value: 'share',
                    child: _MenuRow(icon: Icons.link_rounded, text: '링크로 공유'),
                  ),
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
          // 목록 옆 칸에서는 같은 화면에 목록의 '대본 추가' 버튼도 있다. 화면을 넘길 때 두 버튼이 같은 기본 Hero 태그로
          // 부딪치지 않게 이 버튼의 Hero를 끈다(폰에서는 목록 버튼이 이 버튼으로 바뀌는 효과를 그대로 둔다)
          floatingActionButton: _inPane
              ? FloatingActionButton.extended(heroTag: null, onPressed: openReader, icon: readerIcon, label: readerLabel)
              : FloatingActionButton.extended(onPressed: openReader, icon: readerIcon, label: readerLabel),
          body: LayoutBuilder(
            builder: (context, constraints) => ListView(
              // 몰입 읽기 버튼이 본문 끝을 가리지 않게 아래를 넉넉히 두고, 넓은 창에서는 글줄이 너무 길어지지 않게 양옆을 늘린다
              padding: readablePadding(constraints.maxWidth, const EdgeInsets.fromLTRB(24, 4, 24, 112)),
              children: [
                if (source != null) Text(keepWords(source), style: theme.textTheme.headlineMedium?.copyWith(height: 1.3)),
                if (hasLabels)
                  Padding(
                    padding: EdgeInsets.only(top: source != null ? 14 : 0),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
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
                if (note != null)
                  Padding(
                    padding: EdgeInsets.only(
                      top: source != null || hasLabels || memo != null || speakers.isNotEmpty ? 20 : 0,
                    ),
                    child: _NotePreview(note: note, onTap: openNotes),
                  ),
                // 위에 보여 줄 정보가 없으면 구분선 없이 본문부터 시작한다
                if (source != null || hasLabels || memo != null || speakers.isNotEmpty || note != null) ...[
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
                const SizedBox(height: 48),
                PracticeSection(scriptId: s.id, body: s.body),
              ],
            ),
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

/// 본문 위에 노트 앞부분을 보여 주고, 누르면 노트 화면을 연다.
class _NotePreview extends StatelessWidget {
  const _NotePreview({required this.note, required this.onTap});

  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.outlineVariant)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sticky_note_2_outlined, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text('노트', style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                keepWords(note),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
