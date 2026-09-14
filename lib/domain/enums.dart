/// 연습 기록 종류
enum MediaKind { audio, video }

enum PracticeStatus {
  notStarted('연습 전'),
  practicing('연습 중'),
  memorized('다 외움');

  const PracticeStatus(this.label);
  final String label;
}
