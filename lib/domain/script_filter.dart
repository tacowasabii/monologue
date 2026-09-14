/// 대본 탭·전체·즐겨찾기 목록의 정렬. 모음 안에서는 사용자가 끌어서 정한 순서를 쓴다.
enum ScriptSort {
  updated('최근 수정순'),
  created('최근 만든 순'),
  work('작품명순');

  const ScriptSort(this.label);

  final String label;
}

class ScriptFilter {
  const ScriptFilter({
    this.query = '',
    this.tag,
    this.favoritesOnly = false,
    this.collectionId,
    this.sort = ScriptSort.updated,
  });

  final String query;
  final String? tag;

  /// 즐겨찾기 모음. 화면의 범위라서 걸어 둔 조건([isActive])으로 치지 않는다.
  final bool favoritesOnly;

  /// 이 모음에 든 대본만 본다. 모음 화면의 범위라서 걸어 둔 조건([isActive])으로 치지 않는다.
  /// 모음 안에서는 [sort] 대신 모음에서 정한 순서로 보여 준다.
  final int? collectionId;

  final ScriptSort sort;

  bool get isActive => query.trim().isNotEmpty || tag != null;

  // nullable 필드는 함수로 받아 null로 되돌릴 수 있게 한다: copyWith(tag: () => null)
  ScriptFilter copyWith({
    String? query,
    String? Function()? tag,
    ScriptSort? sort,
  }) =>
      ScriptFilter(
        query: query ?? this.query,
        tag: tag != null ? tag() : this.tag,
        favoritesOnly: favoritesOnly,
        collectionId: collectionId,
        sort: sort ?? this.sort,
      );
}
