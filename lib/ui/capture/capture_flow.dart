import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_scope.dart';
import '../../ocr/assemble_text.dart';

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
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('사진첩에서 선택'),
            subtitle: const Text('여러 장을 골라 하나로 합칠 수 있어요'),
            onTap: () => Navigator.pop(context, _Source.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('카메라로 촬영'),
            onTap: () => Navigator.pop(context, _Source.camera),
          ),
          if (allowManual)
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('직접 입력'),
              onTap: () => Navigator.pop(context, _Source.manual),
            ),
        ],
      ),
    ),
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
          content: ValueListenableBuilder<int>(
            valueListenable: progress,
            builder: (_, done, _) => Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text('글자 인식 중 ${min(done + 1, _paths.length)}/${_paths.length}'),
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
    final text = assembleText(pages);
    progress.dispose();
    if (!mounted) return;
    navigator.pop(); // 진행 대화상자
    if (text.isEmpty) messenger.showSnackBar(const SnackBar(content: Text('글자를 찾지 못했어요. 직접 입력할 수 있어요.')));
    navigator.pop(CaptureResult(
      text: text,
      imagePaths: List.of(_paths),
      failedCount: text.isEmpty ? 0 : pages.where((p) => p.isEmpty).length,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('사진 ${_paths.length}장')),
      body: _paths.isEmpty
          ? const Center(child: Text('사진을 추가해 주세요'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              header: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '길게 눌러 끌면 순서를 바꿀 수 있어요. 위에서부터 차례로 이어붙여요.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              itemCount: _paths.length,
              // onReorderItem은 뺀 항목만큼 newIndex를 이미 보정해서 준다
              onReorderItem: (oldIndex, newIndex) => setState(() {
                _paths.insert(newIndex, _paths.removeAt(oldIndex));
              }),
              itemBuilder: (context, i) => Card(
                key: ValueKey(_paths[i]),
                child: ListTile(
                  minTileHeight: 104,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    // 캡처는 글자가 위에서 시작하므로 위쪽을 보여줘야 순서를 알아볼 수 있다
                    child: Image.file(
                      File(_paths[i]),
                      width: 60,
                      height: 88,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      cacheWidth: 180,
                    ),
                  ),
                  title: Text('${i + 1}번째 사진'),
                  trailing: IconButton(
                    tooltip: '빼기',
                    icon: const Icon(Icons.close),
                    onPressed: _busy ? null : () => setState(() => _paths.removeAt(i)),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: '사진첩에서 추가',
                onPressed: _busy ? null : () => _addMore(_Source.gallery),
                icon: const Icon(Icons.photo_library_outlined),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: '카메라로 추가',
                onPressed: _busy ? null : () => _addMore(_Source.camera),
                icon: const Icon(Icons.photo_camera_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _paths.isEmpty || _busy ? null : _recognize,
                  icon: const Icon(Icons.text_fields),
                  label: const Text('글자 인식'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
