import 'package:flutter_test/flutter_test.dart';
import 'package:monologue/domain/enums.dart';
import 'package:monologue/practice/media_picker.dart';

void main() {
  test('mediaKindOf는 확장자로 음성과 영상을 가린다', () {
    expect(mediaKindOf('/files/voice.M4A'), MediaKind.audio);
    expect(mediaKindOf('/files/memo.mp3'), MediaKind.audio);
    expect(mediaKindOf('/files/take.mov'), MediaKind.video);
    expect(mediaKindOf('/files/take.mp4'), MediaKind.video);
    expect(mediaKindOf('/files/script.pdf'), isNull);
    expect(mediaKindOf('/files/no_extension'), isNull);
  });
}
