import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../common/adaptive.dart';
import '../design/design.dart';

/// 대본에 대해 형식 없이 자유롭게 적는 노트. 저장 버튼을 누를 때만 반영한다.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.script});

  final Script script;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late final String _initial = widget.script.note ?? '';
  late final _text = TextEditingController(text: _initial);
  bool _saving = false;
  bool _leaving = false;

  bool get _dirty => !_leaving && _text.text.trim() != _initial.trim();

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// PopScope가 바뀐 상태를 읽은 뒤에 닫히도록 다음 프레임에 pop한다.
  void _leave() {
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await AppScope.of(context).repo.updateNote(widget.script.id, _text.text);
      if (mounted) _leave();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장하지 못했어요. 다시 시도해 주세요.')));
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showConfirmDialog(
      context,
      title: '저장하지 않고 나갈까요?',
      message: '적은 내용은 사라져요.',
      cancelLabel: '계속 쓰기',
      confirmLabel: '나가기',
      destructive: true,
    );
    if (leave && mounted) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('노트'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('저장'),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(20, 4, 20, 16)),
            // 무엇을 어떻게 적을지는 사람마다 달라서 칸을 나누지 않고 화면 가득 한 칸만 둔다
            child: TextField(
              controller: _text,
              autofocus: _initial.isEmpty,
              expands: true,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
              decoration: const InputDecoration(
                hintText: '인물의 상황, 원하는 것, 떠오르는 생각을 자유롭게 적어 보세요',
                hintMaxLines: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
