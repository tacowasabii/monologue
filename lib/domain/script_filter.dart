import 'enums.dart';

class ScriptFilter {
  const ScriptFilter({
    this.query = '',
    this.gender,
    this.ageRange,
    this.tag,
    this.favoritesOnly = false,
    this.collectionId,
  });

  final String query;
  final Gender? gender;
  final AgeRange? ageRange;
  final String? tag;
  final bool favoritesOnly;

  /// 이 모음에 든 대본만 본다. 모음 화면의 범위라서 걸어 둔 조건([isActive])으로 치지 않는다.
  final int? collectionId;

  bool get isActive =>
      query.trim().isNotEmpty || gender != null || ageRange != null || tag != null || favoritesOnly;

  // nullable 필드는 함수로 받아 null로 되돌릴 수 있게 한다: copyWith(gender: () => null)
  ScriptFilter copyWith({
    String? query,
    Gender? Function()? gender,
    AgeRange? Function()? ageRange,
    String? Function()? tag,
    bool? favoritesOnly,
  }) =>
      ScriptFilter(
        query: query ?? this.query,
        gender: gender != null ? gender() : this.gender,
        ageRange: ageRange != null ? ageRange() : this.ageRange,
        tag: tag != null ? tag() : this.tag,
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
        collectionId: collectionId,
      );
}
