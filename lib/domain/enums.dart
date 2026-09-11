enum Gender {
  any('무관'),
  male('남'),
  female('여');

  const Gender(this.label);
  final String label;
}

enum AgeRange {
  any('무관'),
  teens('10대'),
  twenties('20대'),
  thirties('30대'),
  forties('40대'),
  fiftiesPlus('50대 이상');

  const AgeRange(this.label);
  final String label;
}

enum PracticeStatus {
  notStarted('연습 전'),
  practicing('연습 중'),
  memorized('다 외움');

  const PracticeStatus(this.label);
  final String label;
}
