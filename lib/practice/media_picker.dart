import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

/// 촬영하거나 고른 파일. 길이를 알아내지 못하면 [duration]은 null.
typedef PickedMedia = ({String path, Duration? duration});

/// 영상 촬영·영상 고르기·음성 파일 고르기. 테스트에서 바꿔 끼울 수 있게 나눠 둔다.
abstract class MediaPicker {
  Future<PickedMedia?> recordVideo();

  Future<PickedMedia?> pickVideo();

  Future<PickedMedia?> pickAudio();
}

class PlatformMediaPicker implements MediaPicker {
  final _picker = ImagePicker();

  static const audioExtensions = ['m4a', 'mp3', 'aac', 'wav', 'ogg', 'flac'];

  @override
  Future<PickedMedia?> recordVideo() => _video(ImageSource.camera);

  @override
  Future<PickedMedia?> pickVideo() => _video(ImageSource.gallery);

  Future<PickedMedia?> _video(ImageSource source) async {
    final file = await _picker.pickVideo(source: source);
    if (file == null) return null;
    return (path: file.path, duration: await _videoDuration(file.path));
  }

  @override
  Future<PickedMedia?> pickAudio() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: audioExtensions);
    final path = file?.path;
    if (path == null) return null;
    return (path: path, duration: await _audioDuration(path));
  }

  Future<Duration?> _videoDuration(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      return controller.value.duration;
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  Future<Duration?> _audioDuration(String path) async {
    final player = AudioPlayer();
    try {
      return await player.setFilePath(path);
    } catch (_) {
      return null;
    } finally {
      await player.dispose();
    }
  }
}
