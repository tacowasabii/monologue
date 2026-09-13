import 'package:record/record.dart';

/// 녹음기. 실제 마이크를 쓰지 않는 테스트에서 바꿔 끼울 수 있게 나눠 둔다.
abstract class VoiceRecorder {
  Future<bool> hasPermission();

  /// [path]에 녹음을 쓰기 시작한다.
  Future<void> start(String path);

  Future<void> stop();

  /// 녹음을 멈추고 쓰던 파일을 버린다.
  Future<void> cancel();

  Future<void> dispose();
}

class RecordVoiceRecorder implements VoiceRecorder {
  final _recorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start(String path) => _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);

  @override
  Future<void> stop() async {
    await _recorder.stop();
  }

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Future<void> dispose() => _recorder.dispose();
}
