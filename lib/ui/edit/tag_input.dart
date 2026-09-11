import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in widget.tags)
                InputChip(
                  label: Text('#$t'),
                  labelStyle: TextStyle(color: scheme.onPrimaryContainer, fontSize: 13, fontWeight: FontWeight.w600),
                  backgroundColor: scheme.primaryContainer,
                  side: BorderSide.none,
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  deleteIconColor: scheme.onPrimaryContainer,
                  onDeleted: () => widget.onChanged([...widget.tags]..remove(t)),
                ),
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
      ],
    );
  }
}
