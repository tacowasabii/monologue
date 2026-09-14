import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 연습 기록(녹음·영상) 파일을 앱 지원 디렉터리에 둔다.
/// 영상은 수백 MB가 될 수 있어서 메모리에 올리지 않고 파일째 복사한다.
class MediaStore {
  MediaStore(this.dir);

  final Directory dir;
  int _seq = 0;

  static Future<MediaStore> open() async {
    final base = await getApplicationSupportDirectory();
    return MediaStore(await Directory(p.join(base.path, 'media')).create(recursive: true));
  }

  String pathOf(String fileName) => p.join(dir.path, fileName);

  /// 녹음처럼 이 저장소에 바로 쓸 새 파일 이름.
  String newFileName(String extension) {
    final ext = extension.isEmpty || extension.startsWith('.') ? extension : '.$extension';
    return '${DateTime.now().microsecondsSinceEpoch}_${_seq++}${ext.toLowerCase()}';
  }

  Future<String> importFile(String sourcePath) async {
    final name = newFileName(p.extension(sourcePath));
    await File(sourcePath).copy(pathOf(name));
    return name;
  }

  Future<int> sizeOf(String fileName) async {
    final f = File(pathOf(fileName));
    return await f.exists() ? f.length() : 0;
  }

  Future<void> delete(String fileName) async {
    final f = File(pathOf(fileName));
    if (await f.exists()) await f.delete();
  }
}
