/// 앱 전체에서 쓰는 모서리·간격·크기 값. 색과 글꼴은 `theme.dart`에 있고, 쓰는 규칙은 `docs/design-system.md`에 적는다.
abstract final class AppRadius {
  /// 작은 아이콘 상자, 스낵바, 세그먼트 버튼
  static const small = 12.0;

  /// 버튼, 입력칸, 검색창, 시트 항목
  static const medium = 16.0;

  /// 카드
  static const large = 20.0;

  /// 가운데 창
  static const dialog = 24.0;

  /// 아래에서 올라오는 시트의 위 모서리
  static const sheet = 28.0;
}

abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// 화면 좌우 여백
  static const page = 20.0;
}

abstract final class AppSize {
  /// 창과 아래 막대에 넓게 까는 버튼의 높이
  static const actionButton = 50.0;

  /// 떠 있는 추가 버튼이 목록 마지막 항목을 가리지 않게 목록 아래에 두는 여백
  static const fabClearance = 112.0;

  /// 가운데 창의 최대 폭
  static const dialogMaxWidth = 400.0;
}
