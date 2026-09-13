import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../data/script_repository.dart';
import '../../domain/enums.dart';
import '../../domain/script_notes.dart';
import '../common/pill_chip.dart';
import '../common/section_header.dart';

/// 대본 분석과 작품 맥락을 적는다. 저장 버튼을 누를 때만 반영한다.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.script});

  final Script script;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late final ScriptNotes _initial = widget.script.notes.normalized();
  late final _situation = TextEditingController(text: _initial.situation);
  late final _objective = TextEditingController(text: _initial.objective);
  late final _obstacle = TextEditingController(text: _initial.obstacle);
  late final _author = TextEditingController(text: _initial.author);
  late final _sourceUrl = TextEditingController(text: _initial.sourceUrl);
  late final _synopsis = TextEditingController(text: _initial.synopsis);
  late final _sceneContext = TextEditingController(text: _initial.sceneContext);
  late ScriptMedium? _medium = _initial.medium;
  bool _saving = false;
  bool _leaving = false;

  List<TextEditingController> get _controllers =>
      [_situation, _objective, _obstacle, _author, _sourceUrl, _synopsis, _sceneContext];

  ScriptNotes get _notes => ScriptNotes(
        situation: _situation.text,
        objective: _objective.text,
        obstacle: _obstacle.text,
        author: _author.text,
        medium: _medium,
        sourceUrl: _sourceUrl.text,
        synopsis: _synopsis.text,
        sceneContext: _sceneContext.text,
      ).normalized();

  bool get _dirty => !_leaving && _notes != _initial;

  @override
  void initState() {
    super.initState();
    for (final c in _controllers) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
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
      await AppScope.of(context).repo.updateNotes(widget.script.id, _notes);
      if (mounted) _leave();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장하지 못했어요. 다시 시도해 주세요.')));
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('저장하지 않고 나갈까요? 적은 내용은 사라져요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('계속 쓰기')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('나가기')),
        ],
      ),
    );
    if (leave == true && mounted) _leave();
  }

  Widget _field(TextEditingController c, String label, {String? hint, int minLines = 1, TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          minLines: minLines,
          maxLines: null,
          keyboardType: keyboard ?? TextInputType.multiline,
          decoration: InputDecoration(labelText: label, hintText: hint, alignLabelWithHint: minLines > 1),
        ),
      );

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
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader('분석', first: true),
              _field(_situation, '상황', hint: '누가, 어디서, 언제, 바로 전에 무슨 일이 있었나요', minLines: 2),
              _field(_objective, '원하는 것', hint: '이 인물이 상대에게서 얻고 싶은 것'),
              _field(_obstacle, '가로막는 것', hint: '그걸 얻지 못하게 막는 것'),
              const SectionHeader('작품 맥락'),
              _field(_author, '작가'),
              Text('매체', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final m in ScriptMedium.values)
                    PillChip(
                      label: m.label,
                      selected: m == _medium,
                      onSelected: (_) => setState(() => _medium = m == _medium ? null : m),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _field(_sourceUrl, '출처 링크', keyboard: TextInputType.url),
              _field(_synopsis, '작품 줄거리', minLines: 3),
              _field(_sceneContext, '이 장면 앞뒤', hint: '이 장면 직전과 직후에 일어나는 일', minLines: 3),
            ],
          ),
        ),
      ),
    );
  }
}
