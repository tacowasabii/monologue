import 'package:flutter/material.dart';

import '../common/adaptive.dart';
import '../common/korean_text.dart';

/// 설정 → 사용 방법. 한 번 보고 지나치기 쉬운 기능을 모아 둔다.
class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key});

  static const items = [
    (
      Icons.photo_library_outlined,
      '사진으로 대본 만들기',
      "대본 추가 → 사진첩에서 선택으로 여러 장을 고르면 하나의 대본으로 이어붙여요. 순서는 사진 오른쪽 손잡이를 끌어서 바꿀 수 있어요. "
          "종이 대본은 카메라로 찍으면 되고, 이미 만든 대본에는 편집 화면의 '사진 추가로 이어쓰기'로 뒤에 붙일 수 있어요.",
    ),
    (
      Icons.folder_outlined,
      '모음으로 정리하기',
      "'모음' 탭의 '새 모음'으로 '1차 오디션', '워크숍'처럼 모음을 만들고, 대본 편집 화면에서 넣을 모음을 골라요. "
          '한 대본을 여러 모음에 넣을 수 있고, 모음 안에서 대본을 추가하면 그 모음에 바로 들어가요. '
          '모음 안에서는 대본을 길게 눌러 끌면 순서를 바꿀 수 있고, 모음마다 따로 기억해요. '
          "대본의 ☆를 누르면 대본 탭 맨 위와 '즐겨찾기' 모음에 모여요. "
          '모음을 길게 누르면 이름을 바꾸거나 지울 수 있고, 지워도 대본은 남아요.',
    ),
    (
      Icons.checklist_rounded,
      '대본에 넣을 문단 고르기',
      '사진에서 문단이 여러 개 나오면 문단 고르기 화면이 열려요. 좋아요 수나 해시태그처럼 앱 화면 글자로 보이는 문단은 '
          '체크가 꺼진 채로 시작하니, 대본에 넣을 문단만 남기고 계속을 눌러 주세요.',
    ),
    (
      Icons.error_outline_rounded,
      '확인 필요 표시',
      "손글씨처럼 글자를 확실히 읽지 못했을 수 있는 문단에는 '확인 필요'가 붙어요. 저장하기 전에 본문에서 그 부분이 맞는지 한 번 봐 주세요.",
    ),
    (
      Icons.image_outlined,
      '원본 사진 보관',
      '대본에 쓴 사진은 앱 안에 따로 보관돼요. 사진첩에서 캡처를 지워도 대본 화면의 ⋯ 메뉴 → 원본 보기로 다시 볼 수 있어요. '
          '대본을 지우면 보관한 사진도 함께 지워져요.',
    ),
    (
      Icons.mic_none_rounded,
      '연습 기록 남기기',
      "대본 화면 아래 '연습 기록'에서 대본을 보면서 녹음하거나, 영상을 찍거나, 기기에 있는 음성·영상 파일을 올릴 수 있어요. "
          '기록은 날짜별로 쌓이고, 길게 누르면 지울 수 있어요.',
    ),
    (
      Icons.forum_outlined,
      '대화 대본과 내 역할',
      "편집 화면에서 형식을 '대화'로 고르면 적는 법 예시가 나와요. 줄 앞에 '민수: '처럼 이름과 콜론을 쓰면 인물별로 나뉘고, "
          '본문 아래에서 인물·대사 수와 미리보기로 맞게 적었는지 바로 확인할 수 있어요. '
          '대본 화면에서 내 역할을 고르면 그 인물 대사만 또렷하게 보이고, 고른 역할은 대본마다 기억해요.',
    ),
    (
      Icons.sticky_note_2_outlined,
      '대본 노트',
      '대본 화면의 노트 버튼으로 인물의 상황, 원하는 것, 떠오르는 생각을 정해진 칸 없이 자유롭게 적어 둘 수 있어요. '
          '적은 노트는 본문 위에 앞부분이 보이고, 누르면 이어서 쓸 수 있어요.',
    ),
    (
      Icons.menu_book_rounded,
      '몰입 읽기',
      '대본 화면 아래 몰입 읽기를 누르면 메뉴 없이 대본만 화면 가득 보여요. '
          '읽는 동안 화면이 꺼지지 않고, 화면을 한 번 누르면 닫기와 글자 크기 버튼이 나와요.',
    ),
    (
      Icons.link_rounded,
      '링크로 대본 보내기',
      "대본 화면 ⋯ 메뉴의 '링크로 공유'로 링크를 만들어 메신저로 보내요. 받은 사람은 링크를 눌러 내 대본에 추가하고, 앱이 없으면 웹에서 읽을 수 있어요. "
          '링크는 7일 뒤 사라지고, 설정 → 보낸 링크에서 먼저 지울 수도 있어요. 메모, 사진, 연습 기록은 보내지 않아요.',
    ),
    (
      Icons.ios_share_rounded,
      '기기를 바꿀 때는 백업',
      '대본은 이 기기에 저장돼요(링크로 공유한 대본만 7일 동안 서버에 올라가요). 설정 → 백업 내보내기로 대본과 사진을 파일 하나로 만들어 두고, 새 기기에서 백업에서 복원으로 가져오세요. '
          '연습 기록(녹음·영상)은 내보낼 때 넣을지 고를 수 있어요.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('사용 방법')),
      body: ListView.separated(
        padding: readablePadding(MediaQuery.sizeOf(context).width, const EdgeInsets.fromLTRB(20, 8, 20, 40)),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final (icon, title, body) = items[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 18, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(11)),
                    child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          keepWords(body),
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
