import 'package:flutter/material.dart';

import '../common/adaptive.dart';
import '../common/korean_text.dart';
import 'how_to_illustrations.dart';

/// 가로로 눕힌 폰에서 그림·글 두 칸과 아래 점·버튼 줄이 함께 넘지 않는 폭
const _sideBySideWidth = 860.0;

/// 사용 방법 한 장. 그림 하나와 짧은 안내 몇 줄.
class HowToSlide {
  const HowToSlide(this.title, this.points, this.art);

  final String title;
  final List<String> points;

  /// [howToArtSize] 판에 그린 그림
  final Widget art;
}

/// 한 번 보고 지나치기 쉬운 기능을 대본을 만드는 순서대로 모아 둔다.
const howToSlides = [
  HowToSlide('사진으로 대본 만들기', [
    '사진첩에서 여러 장을 고르면 대본 하나로 이어붙여요',
    '순서는 사진 오른쪽 손잡이를 끌어서 바꿔요',
    '종이 대본은 카메라로 찍으면 돼요',
    "만든 대본 뒤에는 편집 화면의 '사진 추가로 이어쓰기'로 붙여요",
  ], PhotosArt()),
  HowToSlide('넣을 문단 고르기', [
    '사진에서 문단이 여러 개 나오면 대본에 넣을 문단만 남겨요',
    '좋아요 수, 해시태그처럼 앱 화면 글자로 보이는 문단은 꺼진 채로 시작해요',
    "'확인 필요'가 붙은 문단은 글자를 잘못 읽었을 수 있어요. 저장 전에 한 번 봐 주세요",
  ], PickParagraphsArt()),
  HowToSlide('원본 사진 보관', [
    '대본에 쓴 사진은 앱 안에 따로 보관돼요',
    '사진첩에서 캡처를 지워도 대본 화면 ⋯ 메뉴 → 원본 보기로 다시 볼 수 있어요',
    '대본을 지우면 보관한 사진도 함께 지워져요',
  ], OriginalPhotoArt()),
  HowToSlide('모음으로 정리하기', [
    "'모음' 탭에서 '1차 오디션' 같은 모음을 만들고, 대본 편집 화면에서 넣을 모음을 골라요",
    "☆를 누르면 대본 탭 맨 위와 '즐겨찾기' 모음에 모여요",
    '대본을 길게 누르면 여러 편을 골라 지울 수 있어요. 모음 안에서는 ≡를 끌어 순서를 바꾸거나 모음에서 빼요',
    '모음을 길게 누르면 이름을 바꾸거나 지울 수 있어요. 지워도 대본은 남아요',
  ], CollectionsArt()),
  HowToSlide('대화 대본과 내 역할', [
    "편집 화면에서 형식을 '대화'로 고르고, 줄 앞에 '민수:'처럼 이름과 콜론을 붙여요",
    '본문 아래 인물·대사 수와 미리보기로 맞게 적었는지 확인해요',
    '대본 화면에서 내 역할을 고르면 그 인물 대사만 또렷하게 보여요',
  ], DialogueRoleArt()),
  HowToSlide('연기 노트와 몰입 읽기', [
    '연기 노트 버튼으로 인물의 상황, 원하는 것, 떠오르는 생각을 자유롭게 적어요',
    '위쪽 복사 버튼으로 본문 전체를 복사하고, ⋯ 메뉴의 문서로 내보내기로 PDF·워드·텍스트를 만들어요. 인쇄해서 필기할 때 좋아요',
    '몰입 읽기를 누르면 메뉴 없이 대본만 화면 가득 보여요',
    '읽는 동안 화면이 꺼지지 않고, 한 번 누르면 닫기와 글자 크기 버튼이 나와요',
  ], NoteReadingArt()),
  HowToSlide('연습 기록 남기기', [
    "대본 화면 아래 '연습 기록'에서 대본을 보며 녹음하거나 영상을 찍어요",
    '기기에 있는 음성·영상 파일도 올릴 수 있어요',
    '기록은 날짜별로 쌓이고, 길게 누르면 지울 수 있어요',
  ], PracticeArt()),
  HowToSlide('링크로 대본 보내기', [
    "대본 화면 ⋯ 메뉴의 '링크로 공유'로 링크를 만들어 메신저로 보내요",
    '받은 사람은 링크를 눌러 내 대본에 추가하고, 앱이 없으면 웹에서 읽어요',
    '링크는 7일 뒤 사라지고, 설정 → 보낸 링크에서 먼저 지울 수 있어요',
    '사진과 연습 기록은 보내지 않고, 연기 노트는 함께 보낼지 골라요',
  ], ShareLinkArt()),
  HowToSlide('기기를 바꿀 때는 백업', [
    '대본은 이 기기에 저장돼요. 링크로 공유한 대본만 7일 동안 서버에 올라가요',
    '설정 → 백업 내보내기로 대본과 사진을 파일 하나로 만들어 두세요',
    '새 기기에서 설정 → 백업에서 복원으로 가져와요',
    '녹음·영상은 내보낼 때 넣을지 고를 수 있어요',
  ], BackupArt()),
];

/// 사용 방법을 한 장씩 넘겨 보는 화면. 앱을 처음 켰을 때와 설정 → 사용 방법에서 연다.
class HowToScreen extends StatefulWidget {
  const HowToScreen({super.key, this.firstRun = false, this.onDone});

  /// 앱을 처음 켰을 때인지. 건너뛰기가 생기고 마지막 버튼이 '시작하기'가 된다.
  final bool firstRun;

  /// 끝까지 보거나 건너뛰면 부른다. 없으면 화면을 닫는다.
  final VoidCallback? onDone;

  @override
  State<HowToScreen> createState() => _HowToScreenState();
}

class _HowToScreenState extends State<HowToScreen> {
  final _pages = PageController();
  var _page = 0;

  bool get _last => _page == howToSlides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _done() {
    final onDone = widget.onDone;
    if (onDone != null) {
      onDone();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _go(int page) {
    // 움직임 줄이기를 켠 기기에서는 밀지 않고 바로 바꾼다
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(page, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // 가로로 눕힌 폰처럼 낮은 창에서는 점과 버튼을 한 줄에 둬서 그림과 글 자리를 남긴다
    final compact = size.height < 500;
    final dots = Semantics(
      label: '${howToSlides.length}장 중 ${_page + 1}번째',
      child: ExcludeSemantics(
        child: _PageDots(count: howToSlides.length, current: _page),
      ),
    );
    final buttons = [
      if (_page > 0) ...[
        OutlinedButton(
          onPressed: () => _go(_page - 1),
          style: OutlinedButton.styleFrom(minimumSize: const Size(88, 52)),
          child: const Text('이전'),
        ),
        const SizedBox(width: 10),
      ],
      FilledButton(
        onPressed: _last ? _done : () => _go(_page + 1),
        style: FilledButton.styleFrom(minimumSize: const Size(120, 52)),
        child: Text(_last ? (widget.firstRun ? '시작하기' : '완료') : '다음'),
      ),
    ];
    return PopScope(
      // 처음 켰을 때 뒤로 가기는 앱을 닫지 않고 앞 장으로 돌아간다
      canPop: !widget.firstRun || _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(_page - 1);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.firstRun,
          title: Text(widget.firstRun ? '모노로그' : '사용 방법'),
          actions: [
            if (widget.firstRun && !_last) TextButton(onPressed: _done, child: const Text('건너뛰기')),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: howToSlides.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, i) => _SlideView(howToSlides[i]),
                ),
              ),
              Padding(
                padding: readablePadding(
                  size.width,
                  compact ? const EdgeInsets.fromLTRB(24, 8, 24, 12) : const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  maxWidth: compact ? _sideBySideWidth : 480,
                ),
                child: compact
                    ? Row(children: [dots, const Spacer(), ...buttons])
                    : Column(
                        children: [
                          dots,
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              ...buttons.take(buttons.length - 1),
                              Expanded(child: buttons.last),
                            ],
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

class _SlideView extends StatelessWidget {
  const _SlideView(this.slide);

  final HowToSlide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(keepWords(slide.title), style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        for (final point in slide.points)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 10, right: 12),
                  decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Text(
                    keepWords(point),
                    style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final art = _ArtStage(slide.art);
        // 가로로 눕힌 폰처럼 낮고 넓은 자리에서는 그림을 왼쪽, 글을 오른쪽에 둔다
        if (constraints.maxHeight < 420 && constraints.maxWidth >= 560) {
          return Padding(
            padding: readablePadding(constraints.maxWidth, const EdgeInsets.fromLTRB(24, 12, 24, 0), maxWidth: _sideBySideWidth),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: art),
                const SizedBox(width: 28),
                Expanded(
                  child: Center(child: SingleChildScrollView(child: text)),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: readablePadding(constraints.maxWidth, const EdgeInsets.fromLTRB(24, 8, 24, 16), maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: (constraints.maxHeight * 0.45).clamp(160.0, 320.0), width: double.infinity, child: art),
              const SizedBox(height: 28),
              text,
            ],
          ),
        );
      },
    );
  }
}

/// 그림을 옅은 색 판 위에 올리고 자리에 맞춰 늘이거나 줄인다. 꾸밈이라 읽어 주지 않는다.
class _ArtStage extends StatelessWidget {
  const _ArtStage(this.art);

  final Widget art;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          // 그림 속 글자는 판과 함께 줄고 늘어서, 기기 글자 크기를 따로 키우면 판 밖으로 넘친다
          child: MediaQuery.withNoTextScaling(
            child: FittedBox(
              child: SizedBox.fromSize(size: howToArtSize, child: art),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == current ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == current ? scheme.primary : scheme.outline.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
