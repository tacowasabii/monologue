import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 넓은 화면에서 글줄과 입력칸이 이보다 넓어지지 않게 한다. 대본 글꼴로 한 줄에 한글 35자쯤 들어간다.
const readableWidth = 680.0;

/// 목록 옆에 대본을 함께 보여 줄 만큼 넓은 창인지. 펼친 폴드와 아이패드가 여기에 든다.
/// 가로로 눕힌 폰은 폭이 넓어도 높이가 낮아서 한 칸으로 둔다.
bool isWideWindow(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width >= 640 && size.height >= 480;
}

/// 아래 탭 대신 왼쪽 레일을 둘 만큼 넓은 창인지. 펼친 폴드는 이보다 좁아서 아래 탭을 그대로 쓴다.
bool usesSideRail(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width >= 840 && size.height >= 480;
}

/// 폭이 [width]인 자리에서 내용이 [readableWidth]보다 넓어지지 않도록 [padding]의 양옆을 늘린다.
/// 스크롤 영역에 쓰면 여백을 끌어도 스크롤된다. 창 전체를 쓰는 화면은 창 폭을 넘긴다.
EdgeInsets readablePadding(double width, EdgeInsets padding) {
  final extra = math.max(0.0, (width - padding.horizontal - readableWidth) / 2);
  return padding.copyWith(left: padding.left + extra, right: padding.right + extra);
}
