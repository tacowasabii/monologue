import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/script_repository.dart';
import '../../domain/enums.dart';
import '../../domain/script_draft.dart';
import '../capture/capture_flow.dart';
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
  late final TextEditingController _title;
  late final TextEditingController _work;
  late final TextEditingController _character;
  late final TextEditingController _body;
  late Gender _gender;
  late AgeRange _ageRange;
  late PracticeStatus _status;
  late bool _favorite;
  late List<String> _tags;
  late final List<String> _pendingImages = [...widget.newImagePaths];
  List<String> _suggestions = const [];
  bool _suggestionsLoaded = false;
  // 인식 결과처럼 아직 저장하지 않은 내용이 있으면 나갈 때 확인한다
  late bool _dirty = widget.existing == null && (widget.initialBody.isNotEmpty || widget.newImagePaths.isNotEmpty);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing?.script;
    _title = TextEditingController(text: s?.title ?? '');
    _work = TextEditingController(text: s?.work ?? '');
    _character = TextEditingController(text: s?.character ?? '');
    _body = TextEditingController(text: s?.body ?? widget.initialBody);
    _gender = s?.gender ?? Gender.any;
    _ageRange = s?.ageRange ?? AgeRange.any;
    _status = s?.status ?? PracticeStatus.notStarted;
    _favorite = s?.favorite ?? false;
    _tags = [...?widget.existing?.tags];
    for (final c in [_title, _work, _character, _body]) {
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
    for (final c in [_title, _work, _character, _body]) {
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
      title: _title.text,
      body: _body.text,
      work: _work.text,
      character: _character.text,
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge),
      );

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 20);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existing == null ? '새 대본' : '대본 편집'),
          actions: [TextButton(onPressed: _saving ? null : _save, child: const Text('저장'))],
        ),
        // 모든 입력칸이 항상 만들어져 있어야 Form 검증이 빠지지 않는다(ListView는 화면 밖을 만들지 않음)
        body: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.existing != null) ...[
                  OutlinedButton.icon(
                    onPressed: _appendFromPhotos,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('사진 추가로 이어쓰기'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_pendingImages.isNotEmpty) ...[
                  Text('사진 ${_pendingImages.length}장이 원본으로 함께 보관돼요', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: '제목', hintText: '비워두면 본문 첫 줄로'),
                ),
                gap,
                Row(
                  children: [
                    Expanded(child: TextFormField(controller: _work, decoration: const InputDecoration(labelText: '작품명'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(controller: _character, decoration: const InputDecoration(labelText: '인물'))),
                  ],
                ),
                gap,
                _label('성별'),
                SegmentedButton<Gender>(
                  segments: [for (final g in Gender.values) ButtonSegment(value: g, label: Text(g.label))],
                  selected: {_gender},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => setState(() {
                    _gender = v.first;
                    _dirty = true;
                  }),
                ),
                gap,
                DropdownButtonFormField<AgeRange>(
                  initialValue: _ageRange,
                  decoration: const InputDecoration(labelText: '나이대'),
                  items: [for (final a in AgeRange.values) DropdownMenuItem(value: a, child: Text(a.label))],
                  onChanged: (v) => setState(() {
                    _ageRange = v ?? AgeRange.any;
                    _dirty = true;
                  }),
                ),
                gap,
                _label('연습 상태'),
                SegmentedButton<PracticeStatus>(
                  segments: [for (final st in PracticeStatus.values) ButtonSegment(value: st, label: Text(st.label))],
                  selected: {_status},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => setState(() {
                    _status = v.first;
                    _dirty = true;
                  }),
                ),
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
                gap,
                TextFormField(
                  controller: _body,
                  minLines: 10,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: '본문',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
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
