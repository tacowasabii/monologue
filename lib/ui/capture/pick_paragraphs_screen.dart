import 'package:flutter/material.dart';

import '../../ocr/assemble_text.dart';

const _fontSize = 15.0;
const _lineSpacing = 1.6;

/// 본문 한 줄이 차지하는 높이. 체크박스를 첫 줄에 맞춰 놓는 데 쓴다.
const _lineHeight = _fontSize * _lineSpacing;

/// 글꼴은 글자 위쪽 여백이 아래쪽보다 커서, 획이 줄 상자 가운데보다 조금 아래에 앉는다.
/// 상자가 아니라 획에 맞춰 보이도록 체크박스를 내리는 값(에뮬레이터에서 3디바이스px = 1px로 측정).
const _checkboxOpticalNudge = 1.0;

/// 인식한 문단 중 대본에 넣을 것만 고른다.
/// 앱 화면 글자로 보이는 문단은 꺼진 채로 시작하고, 확신도가 낮은 문단은 표시만 한다.
class PickParagraphsScreen extends StatefulWidget {
  const PickParagraphsScreen({super.key, required this.paragraphs});

  final List<Paragraph> paragraphs;

  @override
  State<PickParagraphsScreen> createState() => _PickParagraphsScreenState();
}

class _PickParagraphsScreenState extends State<PickParagraphsScreen> {
  late final List<bool> _selected = [
    for (final p in widget.paragraphs) !p.isChrome,
  ];

  int get _count => _selected.where((s) => s).length;
  bool get _multiplePhotos => widget.paragraphs.map((p) => p.photoNumber).toSet().length > 1;

  void _toggleAll() {
    final turnOn = _count < widget.paragraphs.length;
    setState(() => _selected.fillRange(0, _selected.length, turnOn));
  }

  void _done() {
    Navigator.of(context).pop([
      for (var i = 0; i < widget.paragraphs.length; i++)
        if (_selected[i]) widget.paragraphs[i],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = widget.paragraphs.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('문단 고르기'),
        actions: [
          TextButton(
            onPressed: _toggleAll,
            child: Text(_count < total ? '모두 선택' : '모두 해제'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        itemCount: total + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '대본에 넣을 문단만 남겨 주세요',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$total개 중 $_count개 선택',
                    style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }
          final index = i - 1;
          return _ParagraphCard(
            paragraph: widget.paragraphs[index],
            selected: _selected[index],
            showPhotoNumber: _multiplePhotos,
            onTap: () => setState(() => _selected[index] = !_selected[index]),
          );
        },
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: scheme.outlineVariant))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: FilledButton(
              onPressed: _count == 0 ? null : _done,
              child: Text('선택한 $_count개로 계속'),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParagraphCard extends StatelessWidget {
  const _ParagraphCard({
    required this.paragraph,
    required this.selected,
    required this.showPhotoNumber,
    required this.onTap,
  });

  final Paragraph paragraph;
  final bool selected;
  final bool showPhotoNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labels = [
      if (showPhotoNumber) ('${paragraph.photoNumber}번째 사진', false),
      if (paragraph.needsCheck) ('확인 필요', true),
    ];
    return Card(
      color: selected ? scheme.surfaceContainerLowest : scheme.surfaceContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? scheme.primary.withValues(alpha: 0.5) : scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 16, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 기본 체크박스는 48dp 탭 영역을 차지해 한 줄짜리 카드에도 두 줄 높이를 만든다.
              // 카드 전체가 이미 탭 영역이므로, 한 줄 높이(_lineHeight)로 묶어 카드가 글자만큼만 자라게 한다.
              Transform.translate(
                offset: const Offset(0, _checkboxOpticalNudge),
                child: SizedBox(
                  height: _lineHeight,
                  child: Center(
                    child: Checkbox(
                      value: selected,
                      onChanged: (_) => onTap(),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (labels.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [for (final (text, warn) in labels) _Badge(text: text, warn: warn)],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      paragraph.text,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: _fontSize,
                        height: _lineSpacing,
                        color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.warn});

  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: warn ? scheme.tertiaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (warn) ...[
            Icon(Icons.error_outline_rounded, size: 13, color: scheme.onTertiaryContainer),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: warn ? scheme.onTertiaryContainer : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
