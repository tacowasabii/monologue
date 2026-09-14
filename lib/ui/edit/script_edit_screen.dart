import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../data/script_repository.dart';
import '../../domain/dialogue.dart';
import '../../domain/enums.dart';
import '../../domain/script_draft.dart';
import '../capture/capture_flow.dart';
import '../common/adaptive.dart';
import '../common/korean_text.dart';
import '../common/pill_chip.dart';
import '../common/section_header.dart';
import '../home/collection_name_dialog.dart';
import '../theme.dart';
import 'tag_input.dart';

class ScriptEditScreen extends StatefulWidget {
  const ScriptEditScreen({
    super.key,
    this.existing,
    this.initialBody = '',
    this.newImagePaths = const [],
    this.failedImages = 0,
    this.initialCollectionIds = const [],
  });

  final ScriptDetail? existing;
  final String initialBody;
  final List<String> newImagePaths;
  final int failedImages;

  /// 모음 안에서 새 대본을 만들 때 미리 골라 둘 모음
  final List<int> initialCollectionIds;

  @override
  State<ScriptEditScreen> createState() => _ScriptEditScreenState();
}

class _ScriptEditScreenState extends State<ScriptEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _work;
  late final TextEditingController _memo;
  late final TextEditingController _body;
  late Gender _gender;
  late AgeRange _ageRange;
  // 연습 상태와 즐겨찾기는 이 화면에서 고르지 않지만(즐겨찾기는 목록·대본 화면의 별로 바꾼다),
  // 저장된 값은 덮어쓰지 않고 그대로 넘긴다
  late final PracticeStatus _status;
  late final bool _favorite;
  late bool _dialogue;
  late List<String> _tags;
  late final List<int> _collectionIds;
  late final List<String> _pendingImages = [...widget.newImagePaths];
  Stream<List<Collection>>? _collections;
  List<String> _suggestions = const [];
  bool _suggestionsLoaded = false;
  // 인식 결과처럼 아직 저장하지 않은 내용이 있으면 나갈 때 확인한다
  late bool _dirty = widget.existing == null && (widget.initialBody.isNotEmpty || widget.newImagePaths.isNotEmpty);
  bool _saving = false;

  List<TextEditingController> get _controllers => [_work, _memo, _body];

  @override
  void initState() {
    super.initState();
    final s = widget.existing?.script;
    _work = TextEditingController(text: s?.work ?? '');
    _memo = TextEditingController(text: s?.memo ?? '');
    _body = TextEditingController(text: s?.body ?? widget.initialBody);
    _gender = s?.gender ?? Gender.any;
    _ageRange = s?.ageRange ?? AgeRange.any;
    _status = s?.status ?? PracticeStatus.notStarted;
    _favorite = s?.favorite ?? false;
    // 새 대본은 '이름:' 줄이 두 줄 이상이면 대화 형식으로 시작한다
    _dialogue = s?.dialogue ?? looksLikeDialogue(widget.initialBody);
    _tags = [...?widget.existing?.tags];
    _collectionIds = [...(widget.existing?.collectionIds ?? widget.initialCollectionIds)];
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
    final repo = AppScope.of(context).repo;
    _collections ??= repo.watchAllCollections();
    if (_suggestionsLoaded) return;
    _suggestionsLoaded = true;
    repo.allTags().then((t) {
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

  Future<void> _showPhotoKeptTip() => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('사진도 함께 보관했어요'),
          content: Text(keepWords(
            '대본에 쓴 사진은 앱 안에 따로 저장돼요. 사진첩에서 캡처를 지워도 대본 화면의 ⋯ 메뉴 → 원본 보기로 다시 볼 수 있어요.\n\n'
            '이 안내는 설정 → 사용 방법에서 다시 볼 수 있어요.',
          )),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
        ),
      );

  void _toggleCollection(int id) => setState(() {
        if (!_collectionIds.remove(id)) _collectionIds.add(id);
        _dirty = true;
      });

  Future<void> _newCollection(List<Collection> existing) async {
    final repo = AppScope.of(context).repo;
    final name = await askCollectionName(
      context,
      title: '새 모음',
      confirmLabel: '만들기',
      takenNames: {for (final c in existing) c.name},
    );
    if (name == null) return;
    final id = await repo.createCollection(name);
    if (!mounted) return;
    setState(() {
      _collectionIds.add(id);
      _dirty = true;
    });
  }

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
    final services = AppScope.of(context);
    final repo = services.repo;
    final draft = ScriptDraft(
      body: _body.text,
      work: _work.text,
      memo: _memo.text,
      gender: _gender,
      ageRange: _ageRange,
      status: _status,
      favorite: _favorite,
      tags: _tags,
      dialogue: _dialogue,
      collectionIds: _collectionIds,
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
      // 사진으로 만든 대본을 처음 저장했을 때 한 번만, 사진첩의 캡처를 지워도 된다고 알려 준다
      if (_pendingImages.isNotEmpty && await services.tips.takePhotoKept() && mounted) {
        await _showPhotoKeptTip();
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
            padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(20, 4, 20, 48)),
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
                const SectionHeader('기본 정보', first: true),
                TextFormField(controller: _work, decoration: const InputDecoration(labelText: '작품명')),
                gap,
                TextFormField(
                  controller: _memo,
                  minLines: 2,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: '메모',
                    hintText: '인물, 배우, 회차·장면, 오디션 날짜 등',
                    alignLabelWithHint: true,
                  ),
                ),
                const SectionHeader('배역'),
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
                const SectionHeader('모음 · 태그'),
                _label('모음'),
                StreamBuilder<List<Collection>>(
                  stream: _collections,
                  builder: (context, snap) {
                    final all = snap.data ?? const <Collection>[];
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in all)
                          PillChip(
                            label: c.name,
                            selected: _collectionIds.contains(c.id),
                            onSelected: (_) => _toggleCollection(c.id),
                          ),
                        PillChip(
                          label: '새 모음',
                          icon: Icons.add_rounded,
                          selected: false,
                          onSelected: (_) => _newCollection(all),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                _label('분위기 태그'),
                TagInput(
                  tags: _tags,
                  suggestions: _suggestions,
                  onChanged: (t) => setState(() {
                    _tags = t;
                    _dirty = true;
                  }),
                ),
                const SectionHeader('본문'),
                SegmentedButton<bool>(
                  expandedInsets: EdgeInsets.zero,
                  segments: const [
                    ButtonSegment(value: false, label: Text('독백')),
                    ButtonSegment(value: true, label: Text('대화')),
                  ],
                  selected: {_dialogue},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => setState(() {
                    _dialogue = v.first;
                    _dirty = true;
                  }),
                ),
                if (_dialogue)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      keepWords('줄 앞에 이름과 콜론을 쓰면 인물 대사로 보여요. 괄호로만 된 줄은 지문이에요.'),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _body,
                  minLines: 12,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(fontFamily: serifFamily, fontSize: 16, height: 1.75),
                  decoration: InputDecoration(
                    hintText: _dialogue ? '민수: 왜 그랬어?\n지영: 몰라.' : '대본 내용을 입력하세요',
                    contentPadding: const EdgeInsets.all(18),
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
