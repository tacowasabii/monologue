import 'enums.dart';

class ScriptFilter {
  const ScriptFilter({
    this.query = '',
    this.gender,
    this.ageRange,
    this.status,
    this.tag,
    this.favoritesOnly = false,
  });

  final String query;
  final Gender? gender;
  final AgeRange? ageRange;
  final PracticeStatus? status;
  final String? tag;
  final bool favoritesOnly;

  bool get isActive =>
      query.trim().isNotEmpty ||
      gender != null ||
      ageRange != null ||
      status != null ||
      tag != null ||
      favoritesOnly;

  // nullable 필드는 함수로 받아 null로 되돌릴 수 있게 한다: copyWith(gender: () => null)
  ScriptFilter copyWith({
    String? query,
    Gender? Function()? gender,
    AgeRange? Function()? ageRange,
    PracticeStatus? Function()? status,
    String? Function()? tag,
    bool? favoritesOnly,
  }) =>
      ScriptFilter(
        query: query ?? this.query,
        gender: gender != null ? gender() : this.gender,
        ageRange: ageRange != null ? ageRange() : this.ageRange,
        status: status != null ? status() : this.status,
        tag: tag != null ? tag() : this.tag,
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      );
}
