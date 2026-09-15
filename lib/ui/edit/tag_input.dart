import 'package:flutter/material.dart';

import '../design/design.dart';

/// 쉼표나 완료 키로 태그를 추가하고, 기존 태그를 자동완성으로 제안한다.
class TagInput extends StatefulWidget {
  const TagInput({super.key, required this.tags, required this.suggestions, required this.onChanged});

  final List<String> tags;
  final List<String> suggestions;
  final ValueChanged<List<String>> onChanged;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final next = [...widget.tags];
    for (final part in raw.split(',')) {
      final t = part.replaceAll('#', '').trim();
      if (t.isNotEmpty && !next.contains(t)) next.add(t);
    }
    if (next.length != widget.tags.length) widget.onChanged(next);
    _controller.clear();
  }

  /// 이미 만든 태그 중 아직 붙이지 않은 것. 입력하지 않아도 골라 붙일 수 있게 보여 준다.
  List<String> get _unused => [for (final s in widget.suggestions) if (!widget.tags.contains(s)) s];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final t in widget.tags)
                AppTagChip(label: '#$t', onDeleted: () => widget.onChanged([...widget.tags]..remove(t))),
            ],
          ),
          const SizedBox(height: 10),
        ],
        RawAutocomplete<String>(
          textEditingController: _controller,
          focusNode: _focus,
          optionsBuilder: (value) {
            final q = value.text.replaceAll('#', '').trim();
            if (q.isEmpty) return const Iterable<String>.empty();
            return widget.suggestions.where((s) => s.contains(q) && !widget.tags.contains(s));
          },
          onSelected: _add,
          fieldViewBuilder: (context, controller, focusNode, _) => TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: '예: 슬픔, 코미디 (입력 후 완료)',
              prefixIcon: Icon(Icons.tag_rounded, size: 20, color: scheme.onSurfaceVariant),
            ),
            onChanged: (v) {
              if (v.endsWith(',')) _add(v);
            },
            onSubmitted: (v) {
              _add(v);
              focusNode.requestFocus();
            },
          ),
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Material(
                color: scheme.surfaceContainerLowest,
                elevation: 3,
                shadowColor: scheme.shadow.withValues(alpha: 0.2),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220, maxWidth: 280),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    children: [
                      for (final o in options) ListTile(dense: true, title: Text('#$o'), onTap: () => onSelected(o)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_unused.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('만든 태그', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final s in _unused) AppSuggestionChip(label: '#$s', onPressed: () => _add(s)),
            ],
          ),
        ],
      ],
    );
  }
}
