import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/script_repository.dart';
import '../../domain/enums.dart';
import '../../domain/script_draft.dart';
import '../capture/capture_flow.dart';
import '../common/pill_chip.dart';
import '../theme.dart';
import 'tag_input.dart';

class ScriptEditScreen extends StatefulWidget {
  const ScriptEditScreen({
    super.key,
    this.existing,
    this.initialBody = '',
    this.newImagePaths = const [],
    this.failedImages = 0,
  });

  final ScriptDetail? existing;
  final String initialBody;
  final List<String> newImagePaths;
  final int failedImages;

  @override
  State<ScriptEditScreen> createState() => _ScriptEditScreenState();
}

class _ScriptEditScreenState extends State<ScriptEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _work;
  late final TextEditingController _character;
  late final TextEditingController _memo;
  late final TextEditingController _body;
  late Gender _gender;
  late AgeRange _ageRange;
  // 연습 상태는 화면에서 고르지 않지만, 저장된 값은 덮어쓰지 않고 그대로 넘긴다
  late final PracticeStatus _status;
  late bool _favorite;
  late List<String> _tags;
  late final List<String> _pendingImages = [...widget.newImagePaths];
  List<String> _suggestions = const [];
  bool _suggestionsLoaded = false;
  // 인식 결과처럼 아직 저장하지 않은 내용이 있으면 나갈 때 확인한다
  late bool _dirty = widget.existing == null && (widget.initialBody.isNotEmpty || widget.newImagePaths.isNotEmpty);
  bool _saving = false;

  List<TextEditingController> get _controllers => [_work, _character, _memo, _body];

  @override
  void initState() {
    super.initState();
    final s = widget.existing?.script;
    _work = TextEditingController(text: s?.work ?? '');
    _character = TextEditingController(text: s?.character ?? '');
    _memo = TextEditingController(text: s?.memo ?? '');
    _body = TextEditingController(text: s?.body ?? widget.initialBody);
    _gender = s?.gender ?? Gender.any;
    _ageRange = s?.ageRange ?? AgeRange.any;
    _status = s?.status ?? PracticeStatus.notStarted;
    _favorite = s?.favorite ?? false;
    _tags = [...?widget.existing?.tags];
    for (final c in _controllers) {
      c.addListener(_markDirty);
    }
    if (widget.failedImages > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _snack('사진 ${widget.failedImages}장은 글자를 찾지 못했어요');
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_suggestionsLoaded) return;
    _suggestionsLoaded = true;
    AppScope.of(context).repo.allTags().then((t) {
      if (mounted) setState(() => _suggestions = t);
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() => _dirty = true;

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  /// PopScope가 새 상태를 읽은 뒤에 닫히도록 다음 프레임에 pop한다.
  void _leave([Object? result]) {
    setState(() => _dirty = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop(result);
    });
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = AppScope.of(context).repo;
    final draft = ScriptDraft(
      body: _body.text,
      work: _work.text,
      character: _character.text,
      memo: _memo.text,
      gender: _gender,
      ageRange: _ageRange,
      status: _status,
      favorite: _favorite,
      tags: _tags,
    );
    try {
      final existing = widget.existing;
      final int id;
      if (existing == null) {
        id = await repo.create(draft, imagePaths: _pendingImages);
      } else {
        id = existing.script.id;
        await repo.update(id, draft, newImagePaths: _pendingImages);
      }
      if (!mounted) return;
      _leave(id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('저장하지 못했어요. 다시 시도해 주세요.');
    }
  }

  Future<void> _appendFromPhotos() async {
    final r = await runCapture(context, allowManual: false);
    if (r == null || !mounted) return;
    setState(() {
      final add = r.text.trim();
      if (add.isNotEmpty) {
        _body.text = _body.text.trim().isEmpty ? add : '${_body.text.trimRight()}\n\n$add';
      }
      _pendingImages.addAll(r.imagePaths);
      _dirty = true;
    });
    if (r.failedCount > 0) _snack('사진 ${r.failedCount}장은 글자를 찾지 못했어요');
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('저장하지 않고 나갈까요? 입력한 내용은 사라져요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('계속 편집')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('나가기')),
        ],
      ),
    );
    if (leave == true && mounted) _leave();
  }

  /// 구역 제목과 오른쪽으로 이어지는 가는 선
  Widget _section(String text, {bool first = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: first ? 4 : 32, bottom: 14),
      child: Row(
        children: [
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _label(String text) {
    final theme = Theme.of(context);
    return Padding(
      // 칩은 터치 영역 때문에 위아래 여백이 붙어 있어서 라벨 아래는 좁게 둔다
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _choices<T>(List<T> values, T selected, String Function(T) labelOf, ValueChanged<T> onSelected) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in values) PillChip(label: labelOf(v), selected: v == selected, onSelected: (_) => onSelected(v)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const gap = SizedBox(height: 12);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existing == null ? '새 대본' : '대본 편집'),
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
        // 모든 입력칸이 항상 만들어져 있어야 Form 검증이 빠지지 않는다(ListView는 화면 밖을 만들지 않음)
        body: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.existing != null) ...[
                  OutlinedButton.icon(
                    onPressed: _appendFromPhotos,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                    label: const Text('사진 추가로 이어쓰기'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_pendingImages.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.photo_library_outlined, size: 18, color: scheme.onPrimaryContainer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "사진 ${_pendingImages.length}장이 대본과 함께 보관돼요. 사진첩에서 캡처를 지워도 '원본 보기'로 다시 볼 수 있어요",
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: scheme.onPrimaryContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _section('기본 정보', first: true),
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: _work, decoration: const InputDecoration(labelText: '작품명'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _character, decoration: const InputDecoration(labelText: '인물'))),
                  ],
                ),
                gap,
                TextFormField(
                  controller: _memo,
                  minLines: 2,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: '메모',
                    hintText: '출처, 오디션 날짜, 연기 포인트 등',
                    alignLabelWithHint: true,
                  ),
                ),
                _section('배역'),
                _label('성별'),
                _choices<Gender>(Gender.values, _gender, (g) => g.label, (g) => setState(() {
                      _gender = g;
                      _dirty = true;
                    })),
                const SizedBox(height: 20),
                _label('나이대'),
                _choices<AgeRange>(AgeRange.values, _ageRange, (a) => a.label, (a) => setState(() {
                      _ageRange = a;
                      _dirty = true;
                    })),
                _section('즐겨찾기 · 태그'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('즐겨찾기'),
                  value: _favorite,
                  onChanged: (v) => setState(() {
                    _favorite = v;
                    _dirty = true;
                  }),
                ),
                const SizedBox(height: 8),
                _label('분위기 태그'),
                TagInput(
                  tags: _tags,
                  suggestions: _suggestions,
                  onChanged: (t) => setState(() {
                    _tags = t;
                    _dirty = true;
                  }),
                ),
                _section('본문'),
                TextFormField(
                  controller: _body,
                  minLines: 12,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontFamily: serifFamily, fontSize: 16, height: 1.75),
                  decoration: const InputDecoration(
                    hintText: '대본 내용을 입력하세요',
                    contentPadding: EdgeInsets.all(18),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '본문을 입력해 주세요' : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
