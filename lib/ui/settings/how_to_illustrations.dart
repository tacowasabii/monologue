import 'package:flutter/material.dart';

import '../theme.dart';

/// 사용 방법 그림은 모두 이 크기 판에 그리고, 보여 줄 자리에 맞춰 늘이거나 줄인다.
/// 앱 화면을 그대로 옮기지 않고 기능이 한눈에 보이게 줄여 그린다.
const howToArtSize = Size(300, 210);

TextStyle _style(
  BuildContext context,
  double size, {
  Color? color,
  FontWeight? weight,
  bool serif = false,
  double? height,
}) => TextStyle(
  fontSize: size,
  color: color ?? Theme.of(context).colorScheme.onSurface,
  fontWeight: weight,
  fontFamily: serif ? serifFamily : null,
  height: height,
  letterSpacing: -0.2,
);

/// 사진으로 대본 만들기: 사진 두 장이 대본 하나로 이어진다
class PhotosArt extends StatelessWidget {
  const PhotosArt({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(left: 10, top: 38, child: Transform.rotate(angle: -0.14, child: const _Photo(number: 1))),
        Positioned(left: 62, top: 56, child: Transform.rotate(angle: 0.08, child: const _Photo(number: 2))),
        Positioned(left: 152, top: 92, child: Icon(Icons.arrow_forward_rounded, size: 26, color: scheme.primary)),
        Positioned(
          right: 6,
          top: 14,
          child: _Panel(
            width: 108,
            height: 182,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Text('햄릿', style: _style(context, 13, weight: FontWeight.w700, serif: true)),
                const SizedBox(height: 12),
                const _Lines([80, 72, 78, 56]),
                const SizedBox(height: 14),
                const _Lines([76, 80, 48]),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.image_outlined, size: 13, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: _Text('사진 2장', style: _style(context, 10, color: scheme.onSurfaceVariant)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 넣을 문단 고르기: 앱 화면 글자는 꺼져 있고, 읽기 어려운 문단에는 확인 필요가 붙는다
class PickParagraphsArt extends StatelessWidget {
  const PickParagraphsArt({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dim = scheme.onSurfaceVariant;
    return Center(
      child: SizedBox(
        width: 240,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _Paragraph(selected: true, child: _Lines([150, 164, 116])),
            const SizedBox(height: 8),
            _Paragraph(
              selected: false,
              child: Row(
                children: [
                  Icon(Icons.favorite_border_rounded, size: 12, color: dim),
                  const SizedBox(width: 3),
                  Flexible(
                    child: _Text('1.2만   #독백 #연기', style: _style(context, 11.5, color: dim)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _Paragraph(
              selected: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 11, color: scheme.onTertiaryContainer),
                        const SizedBox(width: 3),
                        _Text(
                          '확인 필요',
                          style: _style(context, 10, weight: FontWeight.w600, color: scheme.onTertiaryContainer),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  const _Lines([158, 108]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 원본 사진 보관: 사진첩에서 지운 캡처도 대본 메뉴의 원본 보기로 볼 수 있다
class OriginalPhotoArt extends StatelessWidget {
  const OriginalPhotoArt({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget tile(int i) {
      // 두 번째 칸은 사진첩에서 지운 캡처
      if (i == 1) {
        return Container(
          width: 42,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.6)),
          ),
          child: Icon(Icons.delete_outline_rounded, size: 15, color: scheme.onSurfaceVariant),
        );
      }
      return Container(
        width: 42,
        height: 32,
        decoration: BoxDecoration(
          color: i.isEven ? scheme.secondaryContainer : scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          left: 8,
          top: 30,
          child: _Panel(
            width: 112,
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Text(
                  '사진첩',
                  style: _style(context, 10.5, weight: FontWeight.w600, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [for (var i = 0; i < 6; i++) tile(i)]),
              ],
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 14,
          child: _Panel(
            width: 152,
            height: 182,
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Text('햄릿', style: _style(context, 13, weight: FontWeight.w700, serif: true)),
                    const Spacer(),
                    Icon(Icons.more_horiz_rounded, size: 18, color: scheme.onSurface),
                  ],
                ),
                const SizedBox(height: 14),
                const _Lines([124, 110, 120, 84, 116, 96]),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: 44,
          child: _Panel(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                  decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.image_outlined, size: 14, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 6),
                      _Text(
                        '원본 보기',
                        style: _style(context, 11.5, weight: FontWeight.w600, color: scheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 12, 4),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      _Text('편집', style: _style(context, 11.5, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 모음으로 정리하기: 즐겨찾기와 직접 만든 모음
class CollectionsArt extends StatelessWidget {
  const CollectionsArt({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SizedBox(
        width: 268,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Folder(icon: Icons.star_rounded, iconColor: favoriteColor(scheme), name: '즐겨찾기', count: '3편'),
            const _Folder(icon: Icons.folder_rounded, name: '1차 오디션', count: '5편'),
            const _Folder(icon: Icons.folder_rounded, name: '워크숍', count: '2편'),
            // 모음 탭 오른쪽 아래에 떠 있는 '새 모음' 버튼
            SizedBox(
              width: 128,
              height: 90,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: ShapeDecoration(color: scheme.onSurface, shape: const StadiumBorder()),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: scheme.surface),
                      const SizedBox(width: 4),
                      _Text('새 모음', style: _style(context, 11.5, weight: FontWeight.w600, color: scheme.surface)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 대화 대본과 내 역할: 고른 인물의 대사만 또렷하다
class DialogueRoleArt extends StatelessWidget {
  const DialogueRoleArt({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SizedBox(
        width: 256,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Text(
                  '내 역할',
                  style: _style(context, 11, weight: FontWeight.w600, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                const _RoleChip('민수', selected: true),
                const SizedBox(width: 6),
                const _RoleChip('지영', selected: false),
              ],
            ),
            const SizedBox(height: 10),
            const _Panel(
              width: 256,
              padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DialogueLine(name: '민수', text: '나 이제 안 갈 거야.', focused: true),
                  SizedBox(height: 7),
                  _DialogueLine(name: '지영', text: '갑자기 왜 그래?', focused: false),
                  SizedBox(height: 7),
                  _DialogueLine(name: '민수', text: '그냥… 이제야 알겠더라.', focused: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 노트와 몰입 읽기: 자유롭게 적는 노트와 대본만 가득한 화면
class NoteReadingArt extends StatelessWidget {
  const NoteReadingArt({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final page = scheme.onInverseSurface;
    return Stack(
      children: [
        Positioned(
          left: 12,
          top: 30,
          child: Transform.rotate(
            angle: -0.05,
            child: Container(
              width: 136,
              height: 124,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: scheme.shadow.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sticky_note_2_outlined, size: 14, color: scheme.onTertiaryContainer),
                      const SizedBox(width: 5),
                      _Text(
                        '연기 노트',
                        style: _style(context, 11, weight: FontWeight.w700, color: scheme.onTertiaryContainer),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Text(
                    '오디션 전날 밤.\n떨리지만 들키고\n싶지 않다.',
                    style: _style(context, 12, serif: true, height: 1.5, color: scheme.onTertiaryContainer),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: Container(
            width: 128,
            height: 186,
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
            decoration: BoxDecoration(
              color: scheme.inverseSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: scheme.shadow.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: page.withValues(alpha: 0.35)),
                      ),
                      child: _Text('가', style: _style(context, 10, color: page.withValues(alpha: 0.75))),
                    ),
                    const Spacer(),
                    Icon(Icons.close_rounded, size: 14, color: page.withValues(alpha: 0.6)),
                  ],
                ),
                const SizedBox(height: 18),
                _Lines(const [100, 90, 98, 70], color: page.withValues(alpha: 0.45), height: 5, gap: 9),
                const SizedBox(height: 16),
                _Lines(const [96, 100, 58], color: page.withValues(alpha: 0.45), height: 5, gap: 9),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 연습 기록 남기기: 녹음·영상·파일과 날짜별 기록
class PracticeArt extends StatelessWidget {
  const PracticeArt({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget action(IconData icon, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: scheme.onPrimaryContainer),
            const SizedBox(width: 4),
            Flexible(
              child: _Text(
                label,
                style: _style(context, 11, weight: FontWeight.w600, color: scheme.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
    return Center(
      child: _Panel(
        width: 256,
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Text('연습 기록', style: _style(context, 12, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                action(Icons.mic_none_rounded, '녹음'),
                const SizedBox(width: 6),
                action(Icons.videocam_outlined, '영상'),
                const SizedBox(width: 6),
                action(Icons.upload_file_outlined, '파일'),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 10),
            const _PracticeRecord(icon: Icons.mic_none_rounded, date: '9월 14일', length: '1:24', video: false),
            const SizedBox(height: 10),
            const _PracticeRecord(icon: Icons.videocam_outlined, date: '9월 12일', length: '0:58', video: true),
          ],
        ),
      ),
    );
  }
}

/// 링크로 대본 보내기: 메신저로 보낸 링크를 받은 사람이 내 대본에 추가한다
class ShareLinkArt extends StatelessWidget {
  const ShareLinkArt({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(
          left: 10,
          bottom: 8,
          child: _Panel(
            width: 176,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Text('받은 대본', style: _style(context, 10, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 3),
                _Text('햄릿 · 3막 1장', style: _style(context, 12.5, weight: FontWeight.w700, serif: true)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
                  decoration: ShapeDecoration(color: scheme.onSurface, shape: const StadiumBorder()),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: scheme.surface),
                      const SizedBox(width: 4),
                      _Text(
                        '내 대본에 추가',
                        style: _style(context, 11, weight: FontWeight.w600, color: scheme.surface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 10,
          top: 6,
          child: Container(
            width: 190,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(color: scheme.shadow.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 4)),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(13)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.link_rounded, size: 13, color: scheme.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: _Text(
                          '모노로그 대본 링크',
                          style: _style(context, 9.5, weight: FontWeight.w600, color: scheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _Text('햄릿 · 3막 1장', style: _style(context, 13.5, weight: FontWeight.w700, serif: true)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 11, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Flexible(
                        child: _Text('7일 동안 열 수 있어요', style: _style(context, 10, color: scheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 기기를 바꿀 때는 백업: 지금 기기에서 파일 하나로 내보내 새 기기에서 복원한다
class BackupArt extends StatelessWidget {
  const BackupArt({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final arrow = Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 22),
      child: Icon(Icons.arrow_forward_rounded, size: 18, color: scheme.primary),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Device(label: '지금 기기'),
        arrow,
        _Captioned(
          label: '파일 하나로',
          child: _Panel(
            // 양옆 기기와 높이를 맞춰야 아래 설명 글이 한 줄에 선다
            width: 84,
            height: 116,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_zip_outlined, size: 28, color: scheme.primary),
                const SizedBox(height: 6),
                _Text('백업 파일', style: _style(context, 10.5, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                _Text('대본 · 사진', style: _style(context, 9.5, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        arrow,
        const _Device(label: '새 기기'),
      ],
    );
  }
}

/// 앱 화면 속 카드처럼 보이는 판
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.width, this.height, this.padding = const EdgeInsets.all(12)});

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(color: scheme.shadow.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

/// 글줄 자리를 막대로 그린다
class _Lines extends StatelessWidget {
  const _Lines(this.widths, {this.color, this.height = 6, this.gap = 7});

  final List<double> widths;
  final Color? color;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.14);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widths.length; i++)
          Container(
            width: widths[i],
            height: height,
            margin: EdgeInsets.only(top: i == 0 ? 0 : gap),
            decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(height)),
          ),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 110,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: scheme.shadow.withValues(alpha: 0.14), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(6)),
            child: _Lines(
              const [52, 46, 50, 38, 48, 28],
              height: 4,
              gap: 6,
              color: scheme.onSecondaryContainer.withValues(alpha: 0.28),
            ),
          ),
        ),
        Positioned(
          left: -6,
          top: -6,
          child: Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
            child: _Text(
              '$number',
              style: _style(context, 11, weight: FontWeight.w700, color: scheme.onPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph({required this.selected, required this.child});

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: selected ? scheme.surfaceContainerLowest : scheme.surfaceContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? scheme.primary.withValues(alpha: 0.5) : scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: selected ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: selected ? scheme.primary : scheme.outline, width: 1.5),
            ),
            child: selected ? Icon(Icons.check_rounded, size: 12, color: scheme.onPrimary) : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Folder extends StatelessWidget {
  const _Folder({required this.icon, required this.name, required this.count, this.iconColor});

  final IconData icon;
  final String name;
  final String count;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Panel(
      width: 128,
      height: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor ?? scheme.primary),
          const Spacer(),
          _Text(name, style: _style(context, 12.5, weight: FontWeight.w700)),
          const SizedBox(height: 1),
          _Text(count, style: _style(context, 10.5, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip(this.label, {required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: ShapeDecoration(
        color: selected ? scheme.onSurface : Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: selected ? scheme.onSurface : scheme.outlineVariant)),
      ),
      child: _Text(
        label,
        style: _style(context, 11.5, weight: FontWeight.w600, color: selected ? scheme.surface : scheme.onSurface),
      ),
    );
  }
}

class _DialogueLine extends StatelessWidget {
  const _DialogueLine({required this.name, required this.text, required this.focused});

  final String name;
  final String text;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Text(
          name,
          style: _style(
            context,
            10.5,
            weight: FontWeight.w700,
            color: focused ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        _Text(
          text,
          style: _style(context, 13.5, serif: true, color: scheme.onSurface.withValues(alpha: focused ? 1 : 0.38)),
        ),
      ],
    );
  }
}

class _PracticeRecord extends StatelessWidget {
  const _PracticeRecord({required this.icon, required this.date, required this.length, required this.video});

  final IconData icon;
  final String date;
  final String length;
  final bool video;

  static const _wave = <double>[6, 12, 18, 10, 20, 14, 8, 16, 22, 12, 6, 14];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: scheme.secondaryContainer, shape: BoxShape.circle),
          child: Icon(icon, size: 14, color: scheme.onSecondaryContainer),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Text(date, style: _style(context, 11.5, weight: FontWeight.w600)),
            _Text(length, style: _style(context, 10, color: scheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: video
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 48,
                    height: 28,
                    decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(6)),
                    child: Icon(Icons.play_arrow_rounded, size: 16, color: scheme.onTertiaryContainer),
                  ),
                )
              : Row(
                  children: [
                    for (final h in _wave)
                      Container(
                        width: 3,
                        height: h,
                        margin: const EdgeInsets.only(right: 2.5),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
        ),
        Icon(Icons.play_circle_outline_rounded, size: 18, color: scheme.onSurfaceVariant),
      ],
    );
  }
}

class _Device extends StatelessWidget {
  const _Device({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Captioned(
      label: label,
      child: Container(
        width: 66,
        height: 116,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.35), width: 1.5),
        ),
        child: const _Lines([48, 40, 46, 30, 44], height: 4, gap: 7),
      ),
    );
  }
}

class _Captioned extends StatelessWidget {
  const _Captioned({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 8),
        _Text(
          label,
          style: _style(context, 10.5, weight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// 그림 속 글자. 기기 글꼴마다 글자 폭이 달라도 줄이 바뀌어 판을 넘치지 않도록 줄바꿈하지 않는다.
class _Text extends StatelessWidget {
  const _Text(this.data, {this.style});

  final String data;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(data, style: style, softWrap: false);
}
