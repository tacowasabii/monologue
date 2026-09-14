import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

import '../domain/enums.dart';

/// 촬영하거나 고른 파일. 길이를 알아내지 못하면 [duration]은 null.
typedef PickedMedia = ({String path, MediaKind kind, Duration? duration});

const audioExtensions = ['m4a', 'mp3', 'aac', 'wav', 'ogg', 'flac'];
const videoExtensions = ['mp4', 'mov', 'm4v', '3gp', 'webm', 'mkv'];

/// 확장자로 음성인지 영상인지 가린다. 둘 다 아니면 null.
MediaKind? mediaKindOf(String path) {
  final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
  if (audioExtensions.contains(ext)) return MediaKind.audio;
  if (videoExtensions.contains(ext)) return MediaKind.video;
  return null;
}

/// 파일에서 고른 것이 음성도 영상도 아닐 때
class UnsupportedMediaFile implements Exception {
  const UnsupportedMediaFile();
}

/// 영상 촬영과 파일 고르기. 테스트에서 바꿔 끼울 수 있게 나눠 둔다.
abstract class MediaPicker {
  Future<PickedMedia?> recordVideo();

  /// 사진첩에서 영상을 고른다.
  Future<PickedMedia?> pickFromGallery();

  /// 파일 앱에서 음성이나 영상 파일을 고른다. 종류는 확장자로 정한다.
  Future<PickedMedia?> pickFromFiles();

  /// 음성 파일의 실제 재생 길이. 읽지 못하면 null.
  Future<Duration?> audioDuration(String path);
}

class PlatformMediaPicker implements MediaPicker {
  final _picker = ImagePicker();

  @override
  Future<PickedMedia?> recordVideo() => _video(ImageSource.camera);

  @override
  Future<PickedMedia?> pickFromGallery() => _video(ImageSource.gallery);

  Future<PickedMedia?> _video(ImageSource source) async {
    final file = await _picker.pickVideo(source: source);
    if (file == null) return null;
    return (path: file.path, kind: MediaKind.video, duration: await _videoDuration(file.path));
  }

  @override
  Future<PickedMedia?> pickFromFiles() async {
    // 안드로이드에서는 확장자를 MIME으로 바꿔 거르는데 m4a가 audio/mpeg로 바뀌어,
    // 아이폰 음성 메모 같은 .m4a 파일이 파일 화면에서 흐리게 막혀 고를 수 없다.
    // 그래서 안드로이드는 모든 파일을 보여 주고 아래 mediaKindOf로 직접 거른다.
    final file = await FilePicker.pickFile(
      type: Platform.isAndroid ? FileType.any : FileType.custom,
      allowedExtensions: Platform.isAndroid ? null : [...audioExtensions, ...videoExtensions],
    );
    final path = file?.path;
    if (path == null) return null;
    final kind = mediaKindOf(path);
    if (kind == null) throw const UnsupportedMediaFile();
    final duration = kind == MediaKind.audio ? await _audioDuration(path) : await _videoDuration(path);
    return (path: path, kind: kind, duration: duration);
  }

  @override
  Future<Duration?> audioDuration(String path) => _audioDuration(path);

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
