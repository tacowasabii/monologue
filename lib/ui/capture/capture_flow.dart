import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_scope.dart';
import '../../ocr/assemble_text.dart';
import '../common/adaptive.dart';
import 'pick_paragraphs_screen.dart';

class CaptureResult {
  const CaptureResult({required this.text, required this.imagePaths, this.failedCount = 0});

  final String text;
  final List<String> imagePaths;

  /// 글자를 하나도 찾지 못한 사진 수(인식 오류 포함)
  final int failedCount;
}

enum _Source { gallery, camera, manual }

final _picker = ImagePicker();

/// 사진 선택 → 순서 정렬 → 글자 인식. 취소하면 null.
Future<CaptureResult?> runCapture(BuildContext context, {bool allowManual = true}) async {
  final source = await showModalBottomSheet<_Source>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(allowManual ? '대본 추가' : '사진으로 이어쓰기', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '대본이 담긴 사진을 고르면 글자를 읽어 와요',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                title: '사진첩에서 선택',
                subtitle: '여러 장을 골라 하나로 합칠 수 있어요',
                onTap: () => Navigator.pop(context, _Source.gallery),
              ),
              _SourceTile(
                icon: Icons.photo_camera_outlined,
                title: '카메라로 촬영',
                subtitle: '종이 대본을 바로 찍어요',
                onTap: () => Navigator.pop(context, _Source.camera),
              ),
              if (allowManual)
                _SourceTile(
                  icon: Icons.edit_note_rounded,
                  title: '직접 입력',
                  subtitle: '사진 없이 글로 적어요',
                  onTap: () => Navigator.pop(context, _Source.manual),
                ),
            ],
          ),
        ),
      );
    },
  );
  if (source == null || !context.mounted) return null;
  if (source == _Source.manual) return const CaptureResult(text: '', imagePaths: []);
  final first = await _pick(context, source);
  if (first.isEmpty || !context.mounted) return null;
  return Navigator.of(context).push<CaptureResult>(
    MaterialPageRoute(builder: (_) => _ArrangeScreen(initial: first)),
  );
}

Future<List<String>> _pick(BuildContext context, _Source source) async {
  try {
    if (source == _Source.gallery) {
      final files = await _picker.pickMultiImage(maxWidth: 2400, imageQuality: 90);
      return [for (final f in files) f.path];
    }
    final f = await _picker.pickImage(source: ImageSource.camera, maxWidth: 2400, imageQuality: 90);
    return f == null ? const [] : [f.path];
  } on PlatformException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.code.contains('access_denied')
            ? '사진/카메라 권한이 필요해요. 설정 앱에서 허용해 주세요.'
            : '사진을 불러오지 못했어요.'),
      ));
    }
    return const [];
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 22, color: scheme.onPrimaryContainer),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Icon(Icons.chevron_right_rounded, color: scheme.outline),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _ArrangeScreen extends StatefulWidget {
  const _ArrangeScreen({required this.initial});

  final List<String> initial;

  @override
  State<_ArrangeScreen> createState() => _ArrangeScreenState();
}

class _ArrangeScreenState extends State<_ArrangeScreen> {
  late final List<String> _paths = widget.initial.toSet().toList();
  bool _busy = false;

  Future<void> _addMore(_Source source) async {
    final more = await _pick(context, source);
    if (more.isEmpty || !mounted) return;
    setState(() => _paths.addAll(more.where((p) => !_paths.contains(p))));
  }

  Future<void> _recognize() async {
    final ocr = AppScope.of(context).ocr;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final progress = ValueNotifier<int>(0);
    setState(() => _busy = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('글자를 읽는 중이에요'),
          content: ValueListenableBuilder<int>(
            valueListenable: progress,
            builder: (context, done, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: (done + 1) / _paths.length),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 12),
                Text('${min(done + 1, _paths.length)} / ${_paths.length}장'),
              ],
            ),
          ),
        ),
      ),
    );

    final pages = <List<OcrBlock>>[];
    for (var i = 0; i < _paths.length; i++) {
      progress.value = i;
      try {
        pages.add(await ocr.recognize(_paths[i]));
      } catch (_) {
        pages.add(const []);
      }
    }
    progress.dispose();
    if (!mounted) return;
    navigator.pop(); // 진행 대화상자

    final paragraphs = paragraphsOf(pages);
    if (paragraphs.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('글자를 찾지 못했어요. 직접 입력할 수 있어요.')));
      navigator.pop(CaptureResult(text: '', imagePaths: List.of(_paths)));
      return;
    }

    // 문단이 하나뿐이면 고를 것이 없다
    var picked = paragraphs;
    if (paragraphs.length > 1) {
      final chosen = await navigator.push<List<Paragraph>>(
        MaterialPageRoute(builder: (_) => PickParagraphsScreen(paragraphs: paragraphs)),
      );
      // 뒤로 가면 사진을 그대로 둔 채 다시 인식할 수 있게 한다
      if (chosen == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      picked = chosen;
    }
    if (!mounted) return;
    if (picked.any((p) => p.needsCheck)) {
      messenger.showSnackBar(const SnackBar(content: Text('확인 필요로 표시된 문단이 있어요. 본문을 한 번 봐 주세요.')));
    }
    navigator.pop(CaptureResult(
      text: textOf(picked),
      imagePaths: List.of(_paths),
      failedCount: pages.where((p) => p.isEmpty).length,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final squareButton = IconButton.styleFrom(
      fixedSize: const Size(52, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
    );
    return Scaffold(
      appBar: AppBar(title: Text('사진 ${_paths.length}장')),
      body: _paths.isEmpty
          ? Center(
              child: Text('사진을 추가해 주세요', style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
            )
          : ReorderableListView.builder(
              padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(20, 4, 20, 16)),
              header: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                child: Text(
                  '오른쪽 손잡이를 끌거나 길게 눌러 순서를 바꿀 수 있어요. 위에서부터 차례로 이어붙여요.',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.5),
                ),
              ),
              itemCount: _paths.length,
              // onReorderItem은 뺀 항목만큼 newIndex를 이미 보정해서 준다
              onReorderItem: (oldIndex, newIndex) => setState(() {
                _paths.insert(newIndex, _paths.removeAt(oldIndex));
              }),
              proxyDecorator: (child, _, animation) => AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Material(
                  color: Colors.transparent,
                  elevation: 8 * Curves.easeOut.transform(animation.value),
                  shadowColor: scheme.shadow.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  child: child,
                ),
                child: child,
              ),
              itemBuilder: (context, i) => Padding(
                key: ValueKey(_paths[i]),
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              // 캡처는 글자가 위에서 시작하므로 위쪽을 보여줘야 순서를 알아볼 수 있다
                              child: Image.file(
                                File(_paths[i]),
                                width: 64,
                                height: 88,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                cacheWidth: 192,
                              ),
                            ),
                            Positioned(
                              left: 6,
                              top: 6,
                              child: Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: scheme.onSurface, shape: BoxShape.circle),
                                child: Text(
                                  '${i + 1}',
                                  style: theme.textTheme.labelSmall?.copyWith(color: scheme.surface, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Text('${i + 1}번째 사진', style: theme.textTheme.titleMedium)),
                        IconButton(
                          tooltip: '빼기',
                          icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
                          onPressed: _busy ? null : () => setState(() => _paths.removeAt(i)),
                        ),
                        ReorderableDragStartListener(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.drag_indicator_rounded, color: scheme.outline),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: scheme.outlineVariant))),
        child: SafeArea(
          child: Padding(
            padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(20, 12, 20, 12)),
            child: Row(
              children: [
                IconButton.outlined(
                  style: squareButton,
                  tooltip: '사진첩에서 추가',
                  onPressed: _busy ? null : () => _addMore(_Source.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  style: squareButton,
                  tooltip: '카메라로 추가',
                  onPressed: _busy ? null : () => _addMore(_Source.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _paths.isEmpty || _busy ? null : _recognize,
                    icon: const Icon(Icons.document_scanner_outlined, size: 20),
                    label: const Text('글자 인식'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
